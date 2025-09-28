define generateCrd
  nix build .#generated.$(1) --out-link ./generated/$(1)
endef


p:
	nixidy switch ./\#dev
	git add .
	g p $(shell date +%M)

gen:
	nix build .#generators.$(p) --out-link ./generated/$(p).nix
	echo Generated: ./generated/$(p).nix
