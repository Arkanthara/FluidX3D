# Vérifier si le répertoire et le programme sont fournis
if ($args.Count -lt 2) {
    Write-Host "Usage: .\run_final_2.ps1 <répertoire> <programme> [arguments...]"
    exit 1
}

# Répertoire de travail
$work_dir = $args[0]
$args = $args[1..$args.Count]

# Programme à exécuter et ses arguments
$program = $args[0]
$args = $args[1..$args.Count]

# Fichier de sortie pour les statistiques
$output_file = "logs/usage_stats.csv"

# Écrire l'en-tête du fichier CSV
"Timestamp,CPU_Usage(%),RAM_Usage(%),GPU_Usage(%),GPU_Memory_Usage(%)" | Out-File -FilePath $output_file -Encoding utf8

# Démarrer le programme dans le répertoire spécifié en arrière-plan et obtenir son PID
$process = if ($args) {
    Start-Process -FilePath ".\$program" -ArgumentList $args -WorkingDirectory $work_dir -PassThru
} else {
    Start-Process -FilePath ".\$program" -WorkingDirectory $work_dir -PassThru
}

$processname = $process.ProcessName

$pid_process = $process.Id

# Obtenir la quantité totale de RAM en Mo
$total_ram = (Get-WmiObject -Class Win32_OperatingSystem).TotalVisibleMemorySize / 1KB

# Fonction pour obtenir l'utilisation du CPU en pourcentage pour le processus spécifique
function Get-CPUUsage {
    $cpu_nb = (Get-WMIObject Win32_ComputerSystem).NumberOfLogicalProcessors
    #Write-Host "Number of cpus: $cpu_nb"
    $cpu_usage = (Get-Counter "\Processus($processname*)\% temps processeur").CounterSamples | Select-Object -ExpandProperty CookedValue
    #Write-Host "Cpu usage: $cpu_usage"
    $cpu_usage = [Decimal]::Round(($cpu_usage / $cpu_nb), 2)
    #Write-Host "Cpu usage: $cpu_usage"
    return $cpu_usage
}
function Get-CPUUsage-old {
    $cpu_usage = Get-Counter "\Process($($process.ProcessName)*)\% Processor Time" |
        Select-Object -ExpandProperty CounterSamples |
        Where-Object { $_.InstanceName -eq "$pid_process" } |
        Select-Object -ExpandProperty CookedValue
    return $cpu_usage
}
# Fonction pour obtenir l'utilisation de la RAM en pourcentage pour le processus spécifique
function Get-RAMUsage {
    $used_ram = (Get-Process -Id $pid_process).WorkingSet64 / 1MB
    return ($used_ram / $total_ram) * 100
}

# Fonction pour obtenir l'utilisation du GPU et de la mémoire GPU
function Get-GPUUsage {
    & nvidia-smi --query-gpu=utilization.gpu,utilization.memory --format=csv,noheader,nounits
}

# Enregistrer l'utilisation des ressources toutes les secondes jusqu'à la fin du processus
Write-Host "Recording resource usage for PID $pid_process..."
while (Get-Process -Id $pid_process -ErrorAction SilentlyContinue) {
    $cpu_usage = Get-CPUUsage
    $ram_usage = Get-RAMUsage
    $gpu = Get-GPUUsage
    $gpu_usage_val, $gpu_mem_usage = $gpu -split ","
    "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'),$cpu_usage,$ram_usage,$gpu_usage_val,$gpu_mem_usage" | Out-File -FilePath $output_file -Append -Encoding utf8
    Start-Sleep -Seconds 1
}

Write-Host "Resource usage recorded in $output_file"

