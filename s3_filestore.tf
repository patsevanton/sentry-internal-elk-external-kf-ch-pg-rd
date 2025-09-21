# Создание статического ключа доступа для учетной записи сервиса в Yandex IAM
resource "yandex_iam_service_account_static_access_key" "filestore_bucket_key" {
  # ID учетной записи сервиса, для которой создается ключ доступа
  service_account_id = yandex_iam_service_account.sa-s3.id

  # Описание для ключа доступа
  description        = "static access key for object storage"
}

# Создание бакета (хранилища) в Yandex Object Storage
resource "yandex_storage_bucket" "filestore" {
  # Название бакета
  bucket     = local.filestore_bucket

  # Важно: команда sentry cleanup не удаляет файлы, хранящиеся во внешнем хранилище, таком как GCS или S3.
  # https://develop.sentry.dev/self-hosted/experimental/external-storage/
  # Правило жизненного цикла объектов в бакете
  lifecycle_rule {
    # Уникальный идентификатор правила
    id      = "delete-after-30-days"
    # Флаг, указывающий, что правило активно
    enabled = true

    # Параметры истечения срока хранения объектов
    expiration {
      # Объекты будут автоматически удаляться через 30 дней после загрузки
      days = 30
    }
  }

  # Доступ и секретный ключ, полученные от статического ключа доступа
  access_key = yandex_iam_service_account_static_access_key.filestore_bucket_key.access_key
  secret_key = yandex_iam_service_account_static_access_key.filestore_bucket_key.secret_key

  # ID папки, в которой будет размещен бакет
  folder_id = coalesce(local.folder_id, data.yandex_client_config.client.folder_id) # ID folder в Yandex Cloud

  # Указываем зависимость от ресурса IAM-члена, который должен быть создан до бакета
  depends_on = [
    yandex_resourcemanager_folder_iam_member.sa-admin-s3,
  ]
}

# Вывод ключа доступа для бакета (с чувствительным значением)
output "access_key_for_filestore_bucket" {
  # Описание вывода
  description = "access_key filestore_bucket"

  # Значение для вывода (ключ доступа к бакету)
  value       = yandex_storage_bucket.filestore.access_key

  # Указание, что выводимое значение чувствительно
  sensitive   = true
}

# Вывод секретного ключа для бакета (с чувствительным значением)
output "secret_key_for_filestore_bucket" {
  # Описание вывода
  description = "secret_key filestore_bucket"

  # Значение для вывода (секретный ключ для бакета)
  value       = yandex_storage_bucket.filestore.secret_key

  # Указание, что выводимое значение чувствительно
  sensitive   = true
}
