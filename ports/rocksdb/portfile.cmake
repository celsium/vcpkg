include(vcpkg_common_functions)

vcpkg_from_github(
  OUT_SOURCE_PATH SOURCE_PATH
  REPO facebook/rocksdb
  REF v5.13.2
  SHA512 34634710b7b73676dec12779cea5dcfe7eacd224e90352a05f51461c9bb6e559375ce44f5967b4dabaf36efaf228f9b6caedc4116088832c511b5a7ebffd6245
  HEAD_REF master
)

vcpkg_apply_patches(
  SOURCE_PATH ${SOURCE_PATH}
  PATCHES
    "${CMAKE_CURRENT_LIST_DIR}/0002-disable-gtest.patch"
    "${CMAKE_CURRENT_LIST_DIR}/0003-only-build-one-flavor.patch"
    "${CMAKE_CURRENT_LIST_DIR}/0004-zlib-findpackage.patch"
    "${CMAKE_CURRENT_LIST_DIR}/use-find-package.patch"
    "${CMAKE_CURRENT_LIST_DIR}/pass-major-version.patch"
)

file(REMOVE "${SOURCE_PATH}/cmake/modules/Findzlib.cmake")
file(COPY
  "${CMAKE_CURRENT_LIST_DIR}/Findlz4.cmake"
  "${CMAKE_CURRENT_LIST_DIR}/Findsnappy.cmake"
  DESTINATION "${SOURCE_PATH}/cmake/modules"
)

if(VCPKG_CRT_LINKAGE STREQUAL "static")
  set(WITH_MD_LIBRARY OFF)
else()
  set(WITH_MD_LIBRARY ON)
endif()

string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "static" ROCKSDB_DISABLE_INSTALL_SHARED_LIB)
string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "dynamic" ROCKSDB_DISABLE_INSTALL_STATIC_LIB)

set(WITH_LZ4 OFF)
if("lz4" IN_LIST FEATURES)
  set(WITH_LZ4 ON)
endif()

set(WITH_SNAPPY OFF)
if("snappy" IN_LIST FEATURES)
  set(WITH_SNAPPY ON)
endif()

set(WITH_ZLIB OFF)
if("zlib" IN_LIST FEATURES)
  set(WITH_ZLIB ON)
endif()

get_filename_component(ROCKSDB_VERSION "${SOURCE_PATH}" NAME)
string(REPLACE "rocksdb-" "" ROCKSDB_VERSION "${ROCKSDB_VERSION}")
string(REGEX REPLACE "^([0-9]+)." "\\1" ROCKSDB_MAJOR_VERSION "${ROCKSDB_VERSION}")

vcpkg_configure_cmake(
  SOURCE_PATH ${SOURCE_PATH}
  PREFER_NINJA
  OPTIONS
  -DWITH_GFLAGS=0
  -DWITH_SNAPPY=${WITH_SNAPPY}
  -DWITH_LZ4=${WITH_LZ4}
  -DWITH_ZLIB=${WITH_ZLIB}
  -DWITH_TESTS=OFF
  -DROCKSDB_INSTALL_ON_WINDOWS=ON
  -DFAIL_ON_WARNINGS=OFF
  -DWITH_MD_LIBRARY=${WITH_MD_LIBRARY}
  -DPORTABLE=ON
  -DCMAKE_DEBUG_POSTFIX=d
  -DROCKSDB_DISABLE_INSTALL_SHARED_LIB=${ROCKSDB_DISABLE_INSTALL_SHARED_LIB}
  -DROCKSDB_DISABLE_INSTALL_STATIC_LIB=${ROCKSDB_DISABLE_INSTALL_STATIC_LIB}
  -DROCKSDB_VERSION=${ROCKSDB_VERSION}
  -DROCKSDB_VERSION_MAJOR=${ROCKSDB_MAJOR_VERSION}
  -DCMAKE_DISABLE_FIND_PACKAGE_TBB=TRUE
  -DCMAKE_DISABLE_FIND_PACKAGE_NUMA=TRUE
  -DCMAKE_DISABLE_FIND_PACKAGE_gtest=TRUE
  -DCMAKE_DISABLE_FIND_PACKAGE_Git=TRUE
)

vcpkg_install_cmake()

vcpkg_fixup_cmake_targets(CONFIG_PATH lib/cmake/rocksdb)

file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)

file(INSTALL ${SOURCE_PATH}/LICENSE.Apache DESTINATION ${CURRENT_PACKAGES_DIR}/share/rocksdb RENAME copyright)
file(INSTALL ${SOURCE_PATH}/LICENSE.leveldb DESTINATION ${CURRENT_PACKAGES_DIR}/share/rocksdb)

vcpkg_copy_pdbs()
