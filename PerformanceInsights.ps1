$timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddHHmmss")
$outputDir = "hpa_logs"
$outputFile = "$outputDir\${timestamp}_hpa_details.csv"
$nodeFile = "$outputDir\${timestamp}_nodes.csv"
$podFile  = "$outputDir\${timestamp}_pods.csv"

# Create output dir
if (-not (Test-Path $outputDir)) { New-Item -ItemType Directory -Path $outputDir | Out-Null }

# Write headers
if (-not (Test-Path $outputFile)) {
    Add-Content $outputFile "Time(UTC),Namespace,HPA Name,Current CPU (%),Target CPU (%),Current Memory (%),Target Memory (%),Min Pods,Max Pods,Current Replicas,Metric Type,Metric Name,Current Metric Value,Target Metric Value"
}
if (-not (Test-Path $nodeFile)) {
    Add-Content $nodeFile "Time(UTC),Node,CPU Usage (%),Memory Usage (%)"
}
if (-not (Test-Path $podFile)) {
    Add-Content $podFile "Time(UTC),Namespace,Pod Name,CPU Usage (m),Memory Usage (Mi)"
}

# ========== Main Monitoring Loop ==========
while ($true) {
    $now = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    # --- Job 1: HPA Metrics ---
    $hpaJob = Start-Job -ScriptBlock {
        param($now, $outputFile)

        $hpaJson = kubectl get hpa -A -o json | ConvertFrom-Json
        $rows = @()

        foreach ($item in $hpaJson.items) {
            $ns = $item.metadata.namespace
            $name = $item.metadata.name
            $min = $item.spec.minReplicas
            $max = $item.spec.maxReplicas
            $replicas = $item.status.currentReplicas

            $metricsSpec = $item.spec.metrics
            $metricsStatus = $item.status.currentMetrics

            for ($i = 0; $i -lt $metricsSpec.Count; $i++) {
                $specMetric = $metricsSpec[$i]
                $statusMetric = $metricsStatus[$i]

                $metricType = "Unknown"
                $metricName = ""
                $currentValue = "N/A"
                $targetValue = "N/A"
                $curCPU = "N/A"
                $tgtCPU = "N/A"
                $curMem = "N/A"
                $tgtMem = "N/A"

                if ($specMetric.resource) {
                    $metricType = "Resource"
                    $metricName = $specMetric.resource.name

                    if ($metricName -eq "cpu") {
                        $curCPU = $statusMetric.resource.current.averageUtilization
                        $tgtCPU = $specMetric.resource.target.averageUtilization
                    }
                    elseif ($metricName -eq "memory") {
                        $curMem = $statusMetric.resource.current.averageUtilization
                        $tgtMem = $specMetric.resource.target.averageUtilization
                    }

                    $currentValue = $statusMetric.resource.current.averageUtilization
                    $targetValue = $specMetric.resource.target.averageUtilization
                }
                elseif ($specMetric.external) {
                    $metricType = "External"
                    $metricName = $specMetric.external.metric.name
                    $currentValue = $statusMetric.external.current.value ?? $statusMetric.external.current.averageValue
                    $targetValue = $specMetric.external.target.value ?? $specMetric.external.target.averageValue
                }
                elseif ($specMetric.object) {
                    $metricType = "Object"
                    $metricName = $specMetric.object.metric.name
                    $currentValue = $statusMetric.object.current.value
                    $targetValue = $specMetric.object.target.value
                }

                $rows += "$now,$ns,$name,$curCPU,$tgtCPU,$curMem,$tgtMem,$min,$max,$replicas,$metricType,$metricName,$currentValue,$targetValue"
            }
        }

        return $rows
    } -ArgumentList $now, $outputFile

    # --- Job 2: Node Metrics ---
    $nodeJob = Start-Job -ScriptBlock {
        param($now)

        $rows = @()
        $topNodes = kubectl top nodes --no-headers 2>$null
        foreach ($node in $topNodes) {
            $parts = $node -split '\s+'
            if ($parts.Length -ge 4) {
                $rows += "$now,$($parts[0]),$($parts[1]),$($parts[3])"
            }
        }
        return $rows
    } -ArgumentList $now

    # --- Job 3: Pod Metrics ---
    $podJob = Start-Job -ScriptBlock {
        param($now)

        $rows = @()
        $topPods = kubectl top pods -A --no-headers 2>$null
        foreach ($pod in $topPods) {
            $parts = $pod -split '\s+'
            if ($parts.Length -ge 4) {
                $rows += "$now,$($parts[0]),$($parts[1]),$($parts[2]),$($parts[3])"
            }
        }
        return $rows
    } -ArgumentList $now

    # Wait for all jobs to complete
    Wait-Job -Job $hpaJob, $nodeJob, $podJob

    # Retrieve job results and write to files
    Receive-Job -Job $hpaJob | ForEach-Object { Add-Content $outputFile $_ }
    Receive-Job -Job $nodeJob | ForEach-Object { Add-Content $nodeFile $_ }
    Receive-Job -Job $podJob  | ForEach-Object { Add-Content $podFile $_ }

    # Clean up background jobs
    Remove-Job -Job $hpaJob, $nodeJob, $podJob

    Write-Host "[$now] Logged metrics in parallel." -ForegroundColor Green

    Start-Sleep -Seconds 20
}
