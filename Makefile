test: IMAGE=$(shell docker build -q .)
test: image build/bincode
	echo '\n[registries.test]\nindex="https://test.test/test.git"' > build/.cargo_resistry
	echo "Building crate in container" && \
	docker run --rm --user $(shell id -u):$(shell id -g) -v $$PWD/build:/github/home $(IMAGE) "bincode" "" ".cargo_resistry"
	@echo "Making sure config was appended"
	@grep -q 'index="https://test.test/test.git"' build/.cargo/config || exit 1
	@echo "Running cleanup" 
	docker run --rm --user $(shell id -u):$(shell id -g) --entrypoint /usr/local/bin/cleanup.sh -v $$PWD/build:/github/home $(IMAGE)
	@echo "Making sure x86_64-unknown-linux-musl release was created" 
	@[ -d build/bincode/target/x86_64-unknown-linux-musl ] || exit 1
	@echo "Making sure lambda zip was created" 
	@[ -f build/bincode/target/lambda/rbeext_serde_bincode.zip ] || exit 1


image: 
	@docker build .	

.PHONY:
clean:
	@rm -rf build

build/bincode:
	git clone https://github.com/second-state/rust-by-example-ext.git build/rust-by-example-ext
	mv build/rust-by-example-ext/examples/serde/bincode build/
	rm -rf build/rust-by-example