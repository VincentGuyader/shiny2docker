# Test de la fonction set_gitlab_ci avec et sans tags

# Charger la fonction
source("R/set_gitlab_ci.R")

# Test 1: Sans tags
cat("=== Test 1: Sans tags ===\n")
temp_dir1 <- tempdir()
result1 <- set_gitlab_ci(path = temp_dir1)
cat("Résultat:", result1, "\n")

# Afficher le contenu généré
cat("\nContenu généré (sans tags):\n")
content1 <- readLines(file.path(temp_dir1, ".gitlab-ci.yml"))
cat(content1, sep = "\n")

cat("\n\n=== Test 2: Avec tags ===\n")
# Test 2: Avec tags
temp_dir2 <- file.path(tempdir(), "test_with_tags")
dir.create(temp_dir2, showWarnings = FALSE)
result2 <- set_gitlab_ci(path = temp_dir2, tags = c("docker", "linux"))
cat("Résultat:", result2, "\n")

# Afficher le contenu généré
cat("\nContenu généré (avec tags):\n")
content2 <- readLines(file.path(temp_dir2, ".gitlab-ci.yml"))
cat(content2, sep = "\n")

# Vérifier que les tags sont présents
has_tags <- any(grepl("tags:", content2))
cat("\nTags détectés dans le fichier:", has_tags, "\n")
