terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.13.0"
    }
  }
}

provider "docker" {}

data "docker_registry_image" "keycloak" {
  name = "jboss/keycloak:latest"
}

resource "docker_image" "mysqldb" {
  name         = "mysql:5.7"
  keep_locally = true
}

resource "docker_container" "mysqldb" {
  image = docker_image.mysqldb.latest
  name  = "keycloak-sqldb"
  ports {
    internal = 3306
    external = 3307
  }
  env          = ["MYSQL_USER=keycloak", "MYSQL_PASSWORD=keycloak", "MYSQL_ROOT_PASSWORD=password", "MYSQL_DATABASE=keycloak"]
  network_mode = "bridge"
  networks_advanced {
    name = docker_network.keycloak_net.name
  }
}

resource "docker_network" "keycloak_net" {
  name = "keycloak-net"
}

resource "docker_image" "keycloak" {
  name         = data.docker_registry_image.keycloak.name
  keep_locally = true
}

resource "docker_container" "keycloak" {
  image = docker_image.keycloak.latest
  name  = "keycloak-oidc-server"
  env   = ["DB_VENDOR=MYSQL", "DB_ADDR=keycloak-sqldb", "DB_PORT=3306", "DB_DATABASE=keycloak", "DB_USER=keycloak", "DB_PASSWORD=keycloak", "KEYCLOAK_ALWAYS_HTTPS=false", "JDBC_PARAMS=useSSL=false", "KEYCLOAK_USER=admin", "KEYCLOAK_PASSWORD=admin", "KEYCLOAK_LOGLEVEL=ERROR", "PROXY_ADDRESS_FORWARDING=true"]

  network_mode = "bridge"
  networks_advanced {
    name = docker_network.keycloak_net.name
  }

  depends_on = [docker_container.mysqldb]

  ports {
    internal = 8080
    external = 8081
  }
}