#!/bin/bash

# Vérifier si le répertoire et le programme sont fournis
if [ $# -lt 2 ]; then
  echo "Usage: $0 <répertoire> <programme> [arguments...]"
  exit 1
fi

# Répertoire de travail
work_dir=$1
shift

# Programme à exécuter et ses arguments
program="$1"
shift

# Fichier de sortie pour les statistiques
output_file="logs/usage_stats.csv"

# Écrire l'en-tête du fichier CSV
echo "Timestamp,CPU_Usage(%),RAM_Usage(%),GPU_Usage(%),GPU_Memory_Usage(%)" >$output_file

# Démarrer le programme dans le répertoire spécifié en arrière-plan et obtenir son PID
(cd "$work_dir" && ./"$program" "$@") &
pid=$!

# Fonction pour obtenir l'utilisation de la mémoire et du CPU
get_cpu_usage() {
  #ps -p $pid -o %cpu,%mem --no-headers
  pidstat -u -p $pid -I | grep $pid | awk '{print $9}'
}

get_ram_usage() {
  pidstat -r -p $pid -I | grep $pid | awk '{print $9}'
}

# Fonction pour obtenir l'utilisation de la RAM en pourcentage
# get_ram_usage() {
#   free | awk '/Mem:/ {print $3/$2 * 100.0}'
# }

# Fonction pour obtenir l'utilisation du GPU et de la mémoire GPU
get_gpu_usage() {
  nvidia-smi --query-gpu=utilization.gpu,utilization.memory --format=csv,noheader,nounits
}

# Enregistrer l'utilisation des ressources toutes les secondes jusqu'à la fin du processus
echo "Recording resource usage for PID $pid..."
while kill -0 $pid 2>/dev/null; do
  cpu_usage=$(get_cpu_usage)
  ram_usage=$(get_ram_usage)
  gpu=$(get_gpu_usage)
  #cpu_usage=$(echo $cpu | awk '{print $1}')
  #mem_usage=$(echo $cpu | awk '{print $2}')
  gpu_usage_val=$(echo $gpu | awk -F ',' '{print $1}')
  gpu_mem_usage=$(echo $gpu | awk -F ',' '{print $2}')
  echo "$(date +'%Y-%m-%d %H:%M:%S'),$cpu_usage,$ram_usage,$gpu_usage_val,$gpu_mem_usage" >>$output_file
  sleep 1
done

echo "Resource usage recorded in $output_file"
