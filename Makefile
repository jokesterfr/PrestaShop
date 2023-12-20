.PHONY: help install composer assets node_modules front-core admin-default admin-new-theme admin front cs-fixer phpstan scss-fixer es-linter
.DEFAULT_GOAL := install
DEFAULT_COMPOSER = ./tools/composer.phar
COMPOSER ?= $(shell which composer | echo ${DEFAULT_COMPOSER})
ADMIN_DEFAULT_DIR = ./admin-dev/themes/default
ADMIN_NEW_DIR = ./admin-dev/themes/new-theme
FRONT_DIR = ./themes
UI_TESTS_DIR = ./tests/UI

help: ## Display this help menu
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

clean: ## Remove all the files not tracked by git
	@git -c core.excludesfile=/dev/null clean -X -d -f

install: composer node_modules ## Install PHP and Node.js dependencies

$(DEFAULT_COMPOSER): ## Install a local PHP composer tool
	@cd tools; \
	  php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"; \
	  php composer-setup.php; \
	  php -r "unlink('composer-setup.php');";

composer: ${COMPOSER} ## Install PHP dependencies
	${COMPOSER} install
# https://github.com/PrestaShop/PrestaShop/pull/30853
#./bin/console cache:clear --no-warmup

node_modules: ./admin-dev/themes/default/node_modules

$(ADMIN_DEFAULT_DIR)/node_modules:
	@npm ci --prefix ${ADMIN_DEFAULT_DIR}

$(ADMIN_NEW_DIR)/node_modules:
	@npm ci --prefix ${ADMIN_NEW_DIR}

$(FRONT_DIR)/node_modules:
	@npm ci --prefix ${FRONT_DIR}

$(UI_TESTS_DIR)/node_modules:
	@npm ci --prefix ${UI_TESTS_DIR}

assets: admin front ## Builds all the static assets

admin: admin-default admin-new-theme ## Building admin assets

admin-default: $(ADMIN_DEFAULT_DIR)/node_modules ## Building admin default theme assets
	npm --prefix ${ADMIN_DEFAULT_DIR} run build

admin-new-theme: $(ADMIN_NEW_DIR)/node_modules ## Building admin new theme assets
	npm --prefix ${ADMIN_NEW_DIR} run build

front: front-core ## Building front assets

front-core: $(FRONT_DIR)/node_modules ## Building core theme assets
	npm --prefix ${FRONT_DIR} run build

cs-fixer: ## Run php-cs-fixer
	./vendor/bin/php-cs-fixer fix

phpstan: ## Run phpstan analysis
	./vendor/bin/phpstan analyse -c phpstan.neon.dist

scss-fixer: ## Run scss-fix
	npm --prefix ./admin-dev/themes/new-theme run scss-fix
	npm --prefix ./admin-dev/themes/default run scss-fix
	npm --prefix ./themes/classic/_dev run scss-fix

es-linter: ## Run lint-fix
	npm --prefix ./admin-dev/themes/new-theme run lint-fix
	npm --prefix ./admin-dev/themes/default run lint-fix
	npm --prefix ./themes/classic/_dev run lint-fix
	npm --prefix ./themes run lint-fix
