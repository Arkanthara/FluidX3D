# Vérifier si le répertoire et le programme sont fournis
if ($args.Count -lt 2) {
    Write-Host "Usage: .\run_final.ps1 <répertoire> <programme> [arguments...]"
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
"Timestamp,CPU_Usage(%),RAM_Usage(%),GPU_Usage(%),GPU_Memory_Usage(%),GPU_Memory_Access_Usage(%)" | Out-File -FilePath $output_file -Encoding utf8

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
    $cpu_usage = (Get-Counter "\Processus($processname*)\% temps processeur").CounterSamples | Select-Object -ExpandProperty CookedValue
    $cpu_usage = [Decimal]::Round(($cpu_usage / $cpu_nb), 2)
    return $cpu_usage
}

# Fonction pour obtenir l'utilisation de la RAM en pourcentage pour le processus spécifique
function Get-RAMUsage {
    $process_ram = (Get-Process -Id $pid_process).WorkingSet64 / 1MB
    $ram_usage = [Decimal]::Round(($process_ram / $total_ram) * 100, 2)
    return $ram_usage
}

# Fonction pour obtenir l'utilisation du GPU en pourcentage
function Get-GPUUsage {
    $gpu_usage = & nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits
    return [Decimal]::Round([decimal]::Parse($gpu_usage.Trim()), 2)
}


function Get-GPUMemoryAccessUsage {
    $gpu_usage = & nvidia-smi --query-gpu=utilization.memory --format=csv,noheader,nounits
    return [Decimal]::Round([decimal]::Parse($gpu_usage.Trim()), 2)
}

# Fonction pour obtenir l'utilisation de la mémoire GPU en pourcentage
function Get-GPUMemoryUsage {
    $memory_used = & nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits
    $memory_total = & nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits
    $gpu_memory_usage = [Decimal]::Round(([decimal]::Parse($memory_used.Trim()) / [decimal]::Parse($memory_total.Trim())) * 100, 2)
    return $gpu_memory_usage
}

# Enregistrer l'utilisation des ressources toutes les millisecondes jusqu'à la fin du processus
while ($true) {
    if (-not (Get-Process -Id $pid_process -ErrorAction SilentlyContinue)) {
        break
    }
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $cpu_usage = Get-CPUUsage
    $ram_usage = Get-RAMUsage
    $gpu_usage = Get-GPUUsage
    $gpu_memory_usage = Get-GPUMemoryUsage
    $gpu_memory_access_usage = Get-GPUMemoryAccessUsage
    "$timestamp,$cpu_usage,$ram_usage,$gpu_usage,$gpu_memory_usage,$gpu_memory_access_usage" | Out-File -FilePath $output_file -Append -Encoding utf8
    #Start-Sleep -Milliseconds 1
}

Write-Host "Resource usage recorded in $output_file"

