# Ceph-List 轻量化的 Ceph

Ceph 在软件定义存储领域是一个伟大的项目。随着时间的演进，其架构渐渐老化，不适合现代的发展需要。表现为，

1. 其特有的对象存储、块设备存储、文件系统三层的设计导致架构过分复杂，大幅度提升了作为组件复用的可能。
2. 额外的基于 mon 的协调机制，导致 osd 模块的依赖关系不理想。
3. 基于 Boost 的 Async IO 将处理逻辑分解为多个类，导致操作逻辑分散在多个类中，难以维护。
4. 基于 Crush 的路由方法虽然保障了性能和可扩展性，但是过于死板，导致整个系统无法适应非数据中心(典型的，边缘计算场景)下的存储需求
5. 在代码设计中，将控制平面的逻辑与数据平面的逻辑相混合，导致难于优化。典型的表现是当 RBD 启用 Journal 后，在 OSD 层面存在两倍以上的写入放大；

## 项目目标

提供一个轻量级的，最小化的对象存储系统。

1. 缩减项目规模，去掉项目中， mgr 和 mds 模块（及其依赖的更上层模块）， 仅保留 osd 及其他基础模块
2. 移除 osd 到 mon 的依赖关系，引入类似区块链的技术用于进行元数据管理
3. 在兼容原有 Crush 算法的情况下，允许第三方应用系统定制  Placement Group 的处理逻辑
4. 尝试移除 rocksdb， 改用 sqlite 中的 k/v 层（TBD： 性能测试）， 因为现有的 RocksDB 过度复杂
5. 暂时移除 rbd 等块设备支持， 仅保留 Object Storage.
6. 在尽可能的情况下， 引入 Rust

------------------------------
# Ceph - a scalable distributed storage system

Please see http://ceph.com/ for current info.


## Contributing Code

Most of Ceph is dual licensed under the LG的的PL version 2.1 or 3.0.  Some
miscellaneous code is under BSD-style license or is public domain.
The documentation is licensed under Creative Commons
Attribution Share Alike 3.0 (CC-BY-SA-3.0).  There are a handful of headers
included here that are licensed under the GPL.  Please see the file
COPYING for a full inventory of licenses by file.

Code contributions must include a valid "Signed-off-by" acknowledging
the license for the modified or contributed file.  Please see the file
SubmittingPatches.rst for details on what that means and on how to
generate and submit patches.

We do not require assignment of copyright to contribute code; code is
contributed under the terms of the applicable license.


## Checking out the source

You can clone from github with

	git clone git@github.com:ceph/ceph

or, if you are not a github user,

	git clone git://github.com/ceph/ceph

Ceph contains many git submodules that need to be checked out with

	git submodule update --init --recursive


## Build Prerequisites

The list of Debian or RPM packages dependencies can be installed with:

	./install-deps.sh


## Building Ceph

Note that these instructions are meant for developers who are
compiling the code for development and testing.  To build binaries
suitable for installation we recommend you build deb or rpm packages,
or refer to the `ceph.spec.in` or `debian/rules` to see which
configuration options are specified for production builds.

Build instructions:

	./do_cmake.sh
	cd build
	make

(Note: do_cmake.sh now defaults to creating a debug build of ceph that can
be up to 5x slower with some workloads. Please pass 
"-DCMAKE_BUILD_TYPE=RelWithDebInfo" to do_cmake.sh to create a non-debug
release.)

(Note: `make` alone will use only one CPU thread, this could take a while. use
the `-j` option to use more threads. Something like `make -j$(nproc)` would be
a good start.

This assumes you make your build dir a subdirectory of the ceph.git
checkout. If you put it elsewhere, just point `CEPH_GIT_DIR`to the correct
path to the checkout. Any additional CMake args can be specified setting ARGS
before invoking do_cmake. See [cmake options](#cmake-options)
for more details. Eg.

    ARGS="-DCMAKE_C_COMPILER=gcc-7" ./do_cmake.sh

To build only certain targets use:

	make [target name]

To install:

	make install
 
### CMake Options

If you run the `cmake` command by hand, there are many options you can
set with "-D". For example the option to build the RADOS Gateway is
defaulted to ON. To build without the RADOS Gateway:

	cmake -DWITH_RADOSGW=OFF [path to top level ceph directory]

Another example below is building with debugging and alternate locations 
for a couple of external dependencies:

	cmake -DLEVELDB_PREFIX="/opt/hyperleveldb" -DOFED_PREFIX="/opt/ofed" \
	-DCMAKE_INSTALL_PREFIX=/opt/accelio -DCMAKE_C_FLAGS="-O0 -g3 -gdwarf-4" \
	..

To view an exhaustive list of -D options, you can invoke `cmake` with:

	cmake -LH

If you often pipe `make` to `less` and would like to maintain the
diagnostic colors for errors and warnings (and if your compiler
supports it), you can invoke `cmake` with:

	cmake -DDIAGNOSTICS_COLOR=always ..

Then you'll get the diagnostic colors when you execute:

	make | less -R

Other available values for 'DIAGNOSTICS_COLOR' are 'auto' (default) and
'never'.


## Building a source tarball

To build a complete source tarball with everything needed to build from
source and/or build a (deb or rpm) package, run

	./make-dist

This will create a tarball like ceph-$version.tar.bz2 from git.
(Ensure that any changes you want to include in your working directory
are committed to git.)


## Running a test cluster

To run a functional test cluster,

	cd build
	make vstart        # builds just enough to run vstart
	../src/vstart.sh --debug --new -x --localhost --bluestore
	./bin/ceph -s

Almost all of the usual commands are available in the bin/ directory.
For example,

	./bin/rados -p rbd bench 30 write
	./bin/rbd create foo --size 1000

To shut down the test cluster,

	../src/stop.sh

To start or stop individual daemons, the sysvinit script can be used:

	./bin/init-ceph restart osd.0
	./bin/init-ceph stop


## Running unit tests

To build and run all tests (in parallel using all processors), use `ctest`:

	cd build
	make
	ctest -j$(nproc)

(Note: Many targets built from src/test are not run using `ctest`.
Targets starting with "unittest" are run in `make check` and thus can
be run with `ctest`. Targets starting with "ceph_test" can not, and should
be run by hand.)

When failures occur, look in build/Testing/Temporary for logs.

To build and run all tests and their dependencies without other
unnecessary targets in Ceph:

	cd build
	make check -j$(nproc)

To run an individual test manually, run `ctest` with -R (regex matching):

	ctest -R [regex matching test name(s)]

(Note: `ctest` does not build the test it's running or the dependencies needed
to run it)

To run an individual test manually and see all the tests output, run
`ctest` with the -V (verbose) flag:

	ctest -V -R [regex matching test name(s)]

To run an tests manually and run the jobs in parallel, run `ctest` with 
the `-j` flag:

	ctest -j [number of jobs]

There are many other flags you can give `ctest` for better control
over manual test execution. To view these options run:

	man ctest


## Building the Documentation

### Prerequisites

The list of package dependencies for building the documentation can be
found in `doc_deps.deb.txt`:

	sudo apt-get install `cat doc_deps.deb.txt`

### Building the Documentation

To build the documentation, ensure that you are in the top-level
`/ceph` directory, and execute the build script. For example:

	admin/build-doc

