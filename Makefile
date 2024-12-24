.PHONY: test-targets
test-targets:
	multipass launch --name test-target22 22.04
	multipass launch --name test-target24 24.04

.PHONY: delete-targets
delete-targets:
	multipass delete --purge test-target22
	multipass delete --purge test-target24

.PHONY: test
test: test-targets

/opt/homebrew/bin/ansible-lint:
	brew install ansible-lint


.PHONY: lint
lint: /opt/homebrew/bin/ansible-lint
	ansible-lint

/opt/homebrew/bin/kics:
	brew install kics

.PHONY: secure
secure: /opt/homebrew/bin/kics
	kics scan