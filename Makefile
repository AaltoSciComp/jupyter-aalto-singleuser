UPSTREAM_SCIPY_NOTEBOOK_VER=7254cdcfa22b
CRAN_URL=https://cran.microsoft.com/snapshot/2018-12-27/
VER_BASE=0.5.0
VER_STD=0.5.0        # Python
VER_R=0.5.0

TEST_MEM_LIMIT="--memory=2G"

.PHONY: default

default:
	echo "Please specifiy a command to run"

full-rebuild: base standard test-standard


base:
	docker build -t aaltoscienceit/notebook-server-base:$(VER_BASE) . -f Dockerfile.base --build-arg=UPSTREAM_SCIPY_NOTEBOOK_VER=$(UPSTREAM_SCIPY_NOTEBOOK_VER)
standard:
	docker build -t aaltoscienceit/notebook-server:$(VER_STD) . -f Dockerfile.standard --build-arg=VER_BASE=$(VER_BASE)
#r:
#	docker build -t aaltoscienceit/notebook-server-r:0.4.0 --pull=false . -f Dockerfile.r
r:
	docker build -t aaltoscienceit/notebook-server-r-ubuntu:$(VER_R) --pull=false . -f Dockerfile.r-ubuntu --build-arg=VER_BASE=$(VER_BASE) --build-arg=CRAN_URL=$(CRAN_URL)


test-standard:
	mkdir -p /tmp/tests
	rsync -a tests/ /tmp/tests/
	docker run --volume=/tmp/tests:/tests:ro ${TEST_MEM_LIMIT} aaltoscienceit/notebook-server:$(VER_STD) pytest -o cache_dir=/tmp/pytestcache /tests/python/
#	CC="clang" CXX="clang++" jupyter nbconvert --exec --ExecutePreprocessor.timeout=300 pystan_demo.ipynb --stdout
	docker run --volume=/tmp/tests:/tests:ro ${TEST_MEM_LIMIT} aaltoscienceit/notebook-server:$(VER_R) bash -c 'cd /tmp ; git clone https://github.com/avehtari/BDA_py_demos ; cd BDA_py_demos/demos_pystan/ ; CC=clang CXX=clang++ jupyter nbconvert --exec --ExecutePreprocessor.timeout=300 pystan_demo.ipynb --stdout > /dev/null'

test-r:
	mkdir -p /tmp/tests
	rsync -a tests/ /tmp/tests/
	docker run --volume=/tmp/tests:/tests:ro ${TEST_MEM_LIMIT} aaltoscienceit/notebook-server-r-ubuntu:$(VER_R) Rscript /tests/r/test_bayes.r




push-standard:
	docker push aaltoscienceit/notebook-server:$(VER_STD)
push-r:
	docker push aaltoscienceit/notebook-server-r-ubuntu:$(VER_R)
push-dev:
	time docker save aaltoscienceit/notebook-server-r-ubuntu:${VER_STD} | ssh manager ssh jupyter-k8s-node2.cs.aalto.fi 'docker load'
