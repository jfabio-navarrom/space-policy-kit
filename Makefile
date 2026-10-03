.PHONY: check-baseline check-remediated test

check-baseline:
	@conftest test missions/vulpine-earth-baseline.yaml

check-remediated:
	@conftest test missions/vulpine-earth-remediated.yaml

test:
	@conftest verify
