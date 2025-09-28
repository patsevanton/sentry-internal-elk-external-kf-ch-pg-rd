# Получаем информацию о конфигурации клиента Yandex
data "yandex_client_config" "client" {}


# Локальные переменные для настройки инфраструктуры
locals {
  folder_id           = data.yandex_client_config.client.folder_id  # ID папки в Yandex Cloud
}
