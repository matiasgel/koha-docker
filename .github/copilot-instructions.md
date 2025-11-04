# Koha Docker Copilot Instructions

This codebase provides a complete Spanish-localized Koha library management system using Docker, with production-ready configurations and automated operational scripts.

## Architecture Overview

**Core Services Stack:**
- **Koha Container**: Apache webserver + Zebra search + Plack + background workers (ports 8080/8081)
- **MariaDB**: Database backend with optimized configurations
- **RabbitMQ**: Message broker for background jobs (requires stomp plugin)
- **Memcached**: Session and object caching

**Multi-Environment Design:**
- `examples/`: Development/testing with simple docker-compose.yaml
- `prod/`: Production configurations with persistent volumes and security hardening
- `prod/linux/`: Full Linux production stack with Nginx proxy, SSL, systemd integration

## Key Configuration Patterns

**Template System**: Configuration files use envsubst templating in `files/docker/templates/`:
- `koha-sites.conf` → Site-wide Koha settings (domains, ports, prefixes)
- `koha-common.cnf` → MySQL client configuration
- Variables like `${KOHA_DOMAIN}`, `${KOHA_INTRANET_PORT}` are substituted at runtime

**S6 Overlay Services**: Multi-process container managed by s6-overlay in `files/etc/s6-overlay/s6-rc.d/`:
- `apache2/`, `zebra-server/`, `zebra-indexer/`: Core Koha services
- `plack/`, `worker/`, `worker-long-tasks/`: Performance and background processing
- `prepare-koha/`: Initialization script (`02-setup-koha.sh`)

**Environment Hierarchy**:
1. `config-main.env` - Base template with documentation
2. Development: Direct env vars in docker-compose.yaml
3. Production: `.env` files with security-focused defaults

## Development Workflows

**Quick Start Development:**
```bash
cd examples/
docker-compose up -d
# Wait 2-3 minutes for initialization
# Access: http://localhost:8081 (staff), http://localhost:8080 (OPAC)
# Credentials: koha_teolib / example
```

**Production Deployment:**
- Windows: Use `prod/deploy.ps1` with actions (install|start|stop|backup|status)
- Linux: Use `prod/linux/install-debian13.sh` for full automated setup with systemd, nginx, SSL

**Essential Commands:**
- Database backup: `docker exec examples-db-1 mariadb-dump -u root -pexample koha_teolib`
- Service status: `docker-compose -f docker-compose.prod.yaml ps`
- Log access: Logs mount to `./volumes/koha/logs/` in production

## Backup & Migration Strategy

**Three Backup Levels:**
1. **Simple**: `backup-simple.ps1` - Database + config only (for dev/migration)
2. **Complete**: `backup-koha.ps1` - Database + all volumes (full production state)
3. **Production**: `prod/scripts/backup.sh` - Scheduled with retention policies

**Migration Pattern**: All backup scripts create self-documenting archives with restoration instructions embedded in README files.

## Critical Dependencies

**Spanish Localization**: Set `KOHA_LANGS="es-ES"` - this triggers Spanish interface installation during container init.

**RabbitMQ Plugin**: Must enable stomp plugin via `rabbitmq_plugins` file containing `rabbitmq_stomp.` (note the trailing dot).

**Database Initialization**: Uses `MYSQL_PASSWORD` for both DB auth and default web installer user creation.

## File Organization Logic

**Root Level**: Operational scripts (backup-*.ps1, restore-*.ps1, monitor-*.sh)
**files/**: Container internal configurations (templates, cron jobs, s6 services)
**prod/**: Production variants with persistent storage and security hardening
**examples/**: Simplified development setup

When modifying configurations:
- Development: Edit `examples/docker-compose.yaml` directly
- Production: Modify templates in `files/docker/templates/` and production-specific configs in `prod/config/`
- Always test changes in `examples/` environment first

## Security Considerations

Production configurations include:
- Restricted container capabilities (DAC_READ_SEARCH, SYS_NICE only)
- Separate networks for service isolation
- Read-only mounts for configuration files
- Environment-specific credential management through .env files

Never commit production passwords to version control - use `.env` files locally.