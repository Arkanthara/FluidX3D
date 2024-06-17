import matplotlib.pyplot as plt
import pandas as pd

# Lire les données du fichier CSV
log_file = "logs/usage_stats.csv"
df = pd.read_csv(log_file)

# Afficher les premières lignes pour vérifier le contenu
print(df.head())

# Convertir la colonne 'Timestamp' en datetime
df["Timestamp"] = pd.to_datetime(df["Timestamp"])

# Calculer les secondes depuis le début
start_time = df["Timestamp"].iloc[0]
df["Seconds_Since_Start"] = (df["Timestamp"] - start_time).dt.total_seconds()

# Tracer les graphiques de l'utilisation du CPU, de la mémoire et du GPU
plt.figure(figsize=(14, 7))
plt.plot(df["Seconds_Since_Start"], df["CPU_Usage(%)"], label="Utilisation CPU (%)")
# plt.plot(df["Seconds_Since_Start"], df["Memory_Usage(%)"], label="Utilisation Mémoire CPU (%)",)
plt.plot(df["Seconds_Since_Start"], df["RAM_Usage(%)"], label="Utilisation RAM (%)")
plt.plot(df["Seconds_Since_Start"], df["GPU_Usage(%)"], label="Utilisation GPU (%)")
plt.plot(
    df["Seconds_Since_Start"],
    df["GPU_Memory_Usage(%)"],
    label="Utilisation Mémoire GPU (%)",
)
plt.xlabel("Temps (secondes)")
plt.ylabel("Utilisation (%)")
plt.title(
    "Utilisation du CPU, de la Mémoire CPU, du GPU, de la Mémoire GPU et de la RAM"
)
plt.legend()
plt.grid(True)
plt.show()
