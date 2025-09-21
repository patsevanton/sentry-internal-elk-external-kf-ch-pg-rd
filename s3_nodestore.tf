# Создание статического ключа доступа для сервисного аккаунта
resource "yandex_iam_service_account_static_access_key" "nodestore_bucket_key" {
  # Привязка к существующему сервисному аккаунту
  service_account_id = yandex_iam_service_account.sa-s3.id

  # Описание ключа доступа
  description = "static access key for object storage"
}

# Создание бакета для хранения объектов
resource "yandex_storage_bucket" "nodestore" {
  # Имя бакета, которое определено в локальной переменной
  bucket = local.nodestore_bucket

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

  # Привязка статического ключа доступа (access_key) и секретного ключа (secret_key)
  access_key = yandex_iam_service_account_static_access_key.nodestore_bucket_key.access_key
  secret_key = yandex_iam_service_account_static_access_key.nodestore_bucket_key.secret_key

  # Идентификатор папки, в которой будет создан бакет
  folder_id = coalesce(local.folder_id, data.yandex_client_config.client.folder_id) # ID folder в Yandex Cloud

  # Зависимость от другого ресурса, чтобы этот бакет был создан после предоставления прав сервисному аккаунту
  depends_on = [
    yandex_resourcemanager_folder_iam_member.sa-admin-s3,
  ]
}

# Вывод ключа доступа для бакета, чтобы другие ресурсы могли его использовать
output "access_key_for_nodestore_bucket" {
  # Описание, что это ключ доступа
  description = "access_key nodestore_bucket"

  # Значение — это ключ доступа, привязанный к бакету
  value = yandex_storage_bucket.nodestore.access_key

  # Указание, что это чувствительное значение, и его не следует показывать в логах
  sensitive = true
}

# Вывод секретного ключа для бакета
output "secret_key_for_nodestore_bucket" {
  # Описание, что это секретный ключ
  description = "secret_key nodestore_bucket"

  # Значение — это секретный ключ, привязанный к бакету
  value = yandex_storage_bucket.nodestore.secret_key

  # Указание, что это чувствительное значение, и его не следует показывать в логах
  sensitive = true
}
