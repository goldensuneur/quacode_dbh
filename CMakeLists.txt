#
# Main authors:
#    Vincent Barichard <Vincent.Barichard@univ-angers.fr>
#
# Copyright:
#    Vincent Barichard, 2013
#
# Last modified:
#    $Date$ by $Author$
#    $Revision$
#
# This file is part of Quacode:
#    http://quacode.barichard.com
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

CMAKE_MINIMUM_REQUIRED(VERSION 2.8)

PROJECT(SIBus)

# determine, whether we want a static binary
SET(STATIC_LINKING FALSE CACHE BOOL "Build a static binary?")
# do we want static libraries?
IF(STATIC_LINKING)
    # When STATIC_LINKING is TRUE, than cmake looks for libraries ending
    # with .a. This is for linux only!
    SET(CMAKE_FIND_LIBRARY_SUFFIXES ".a")
    SET(CMAKE_EXE_LINKER_FLAGS "-static")
    # Remove flags to get rid off all the -Wl,Bydnamic
    SET(CMAKE_EXE_LINK_DYNAMIC_C_FLAGS)
    SET(CMAKE_EXE_LINK_DYNAMIC_CXX_FLAGS)
    # Use static libs for Boost
    SET(Boost_USE_STATIC_LIBS ON)
    SET(Boost_USE_STATIC_RUNTIME ON)
ENDIF(STATIC_LINKING)

SET(CMAKE_VERBOSE_MAKEFILE TRUE)
SET(GECODE_SRC "${CMAKE_SOURCE_DIR}" CACHE PATH "Path where GeCode source is installed")
SET(GECODE_BIN "${GECODE_SRC}" CACHE PATH "Path where GeCode libs and binaries are installed")

SET(SIBUS_THREAD FALSE CACHE BOOL "Set to true to use thread in SIBus")
SET(LOG_AUDIT FALSE CACHE BOOL "Set to true to generate log output in parallel qcsp algorithm")

INCLUDE(CheckCXXCompilerFlag)
SET(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_MODULE_PATH})


# IF(NOT GECODE_FOUND)
#   MESSAGE(FATAL_ERROR "Gecode is needed, consider to install it")
# ELSE (NOT GECODE_FOUND)
# ICI COMPILER QUACODE
# SI QUACODE S'EST COMPILE

  INCLUDE_DIRECTORIES(${CMAKE_CURRENT_BINARY_DIR})
  INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR})

  ADD_SUBDIRECTORY(quacode)
  INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/quacode)
  INCLUDE_DIRECTORIES(${GECODE_BIN})
  INCLUDE_DIRECTORIES(${GECODE_SRC})

  IF (CMAKE_COMPILER_IS_GNUCXX)
    ADD_DEFINITIONS(-Wall)
    ADD_DEFINITIONS(-Wextra)
    ADD_DEFINITIONS(-Wno-unused-local-typedefs)
    ADD_DEFINITIONS(-fimplement-inlines)
    ADD_DEFINITIONS(-fno-inline-functions)
    ADD_DEFINITIONS(-pipe)
    ADD_DEFINITIONS(-fPIC)
    SET(CMAKE_CXX_FLAGS_DEBUG "-ggdb")
  ENDIF ()

  check_cxx_compiler_flag(-fvisibility=hidden HAVE_VISIBILITY_HIDDEN_FLAG)
  IF (HAVE_VISIBILITY_HIDDEN_FLAG)
    SET(GECODE_GCC_HAS_CLASS_VISIBILITY "/**/")
    ADD_DEFINITIONS(-fvisibility=hidden)
  ENDIF()

  IF (WIN32)
    SET(GECODE_THREADS_WINDOWS 1)
  ELSE ()
    SET(GECODE_THREADS_PTHREADS 1)
  ENDIF ()

  IF (LOG_AUDIT)
    ADD_DEFINITIONS(-DLOG_AUDIT)
  ENDIF()

  SET(SIBUS_HEADERS
    sibus/sibus.hh
    sibus/receivers/receiver-out.hh
    sibus/receivers/receiver-gecode.hh
    sibus/receivers/receiver-compil-certif.hh
    sibus/receivers/receiver-nodecount.hh
  )
  SET(SIBUS_HEADERS_NEED_THREADS
    sibus/receivers/receiver-network.hh
  )
  SET(SIBUS_HPP
    sibus/sibus.hpp
  )
  SET(SIBUS_SRCS
    sibus/sibus.cpp
    sibus/receivers/receiver-out.cpp
    sibus/receivers/receiver-network.cpp
    sibus/receivers/receiver-gecode.cpp
    sibus/receivers/receiver-compil-certif.cpp
    sibus/receivers/receiver-nodecount.cpp
  )
  SET(SIBUS_SRCS_NEED_THREADS
    sibus/receivers/receiver-network.cpp
  )
SET(SIBUS_EXAMPLES_SRCS
    examples/sample-from-file.cpp
    examples/qbf.cpp
    examples/qdimacs.cpp
    examples/nim-fibo.cpp
    examples/matrix-game.cpp
    examples/connect-four.cpp
    examples/baker.cpp
    examples/speeddating.cpp
  )
  IF (DISJUNCTION)
    SET(SIBUS_EXAMPLES_SRCS ${SIBUS_EXAMPLES_SRCS} examples/disjunction.cpp)
  ENDIF()

  SET(SIBUS_EXAMPLES_SRCS_NEED_THREADS
    examples/baker-dbh.cpp
    examples/nim-fibo-dbh.cpp
    examples/matrix-game-dbh.cpp
  )
  SOURCE_GROUP("Hpp Files" REGULAR_EXPRESSION ".hpp")

  SET_SOURCE_FILES_PROPERTIES(${ALL_HEADERS} PROPERTIES HEADER_FILE_ONLY TRUE)
  SET_SOURCE_FILES_PROPERTIES(${ALL_HPP} PROPERTIES HEADER_FILE_ONLY TRUE)

  SET(SIBUS_LIBS "")
  SET(EXTRA_SRCS "")
  IF (SIBUS_THREAD)
    FIND_PACKAGE(Threads)
    IF(NOT Threads_FOUND)
      MESSAGE(FATAL_ERROR "Thread (pthread) library are needed, consider to install them or disable SIBus threads.")
    ELSE()
      FIND_PACKAGE(Boost 1.49.0 COMPONENTS system thread)
      IF(NOT Boost_FOUND)
        MESSAGE(STATUS "Try to find local Boost libraries.")
        SET(BOOST_LIBRARYDIR ${CMAKE_CURRENT_BINARY_DIR}/..)
        FIND_PACKAGE(Boost 1.49.0 COMPONENTS system thread)
      ENDIF()
      IF(NOT Boost_FOUND)
        MESSAGE(FATAL_ERROR "Boost thread and system library are needed, consider to install them or disable SIBus threads.")
      ELSE()
        INCLUDE_DIRECTORIES( ${Boost_INCLUDE_DIRS} )
        ADD_DEFINITIONS(-DSIBUS_THREAD)
        ADD_LIBRARY(sibus ${SIBUS_SRCS} ${SIBUS_SRCS_NEED_THREADS} ${SIBUS_HEADERS} ${SIBUS_HEADERS_NEED_THREADS} ${SIBUS_HPP})
        SET(EXTRA_SRCS quacode/qint/branch/view-values.cpp)
        IF (BUILD_SHARED_LIBS)
          SET(SIBUS_LIBS -L${CMAKE_CURRENT_BINARY_DIR} -lsibus ${Boost_SYSTEM_LIBRARY} ${Boost_THREAD_LIBRARY} ${CMAKE_THREAD_LIBS_INIT})
        ELSE()
          SET(SIBUS_LIBS sibus ${Boost_SYSTEM_LIBRARY} ${Boost_THREAD_LIBRARY} ${CMAKE_THREAD_LIBS_INIT})
        ENDIF()
      ENDIF()
    ENDIF()
  ELSE()
    ADD_LIBRARY(sibus ${SIBUS_SRCS} ${SIBUS_HEADERS} ${SIBUS_HPP})
    IF (BUILD_SHARED_LIBS)
      SET(SIBUS_LIBS -L${CMAKE_CURRENT_BINARY_DIR} -lsibus)
    ELSE()
      SET(SIBUS_LIBS sibus)
    ENDIF()
  ENDIF ()
  SET_TARGET_PROPERTIES (sibus PROPERTIES DEFINE_SYMBOL  "BUILD_SIBUS")
  IF (HAVE_VISIBILITY_HIDDEN_FLAG)
    SET_TARGET_PROPERTIES(sibus PROPERTIES COMPILE_FLAGS "-DSIBUS_GCC_HAS_CLASS_VISIBILITY")
  ENDIF ()

  # Add targets for examples
  FOREACH (example ${SIBUS_EXAMPLES_SRCS})
    GET_FILENAME_COMPONENT(exampleBin ${example} NAME_WE)
    ADD_EXECUTABLE(${exampleBin} ${example})
    TARGET_LINK_LIBRARIES(${exampleBin} ${QCSP_LIB} ${SIBUS_LIBS} ${GECODE_LIBRARIES} pthread)

    # set -static, when STATIC_LINKING is TRUE and set LINK_SEARCH_END_STATIC
    # to remove the additional -bdynamic from the linker line.
    IF(STATIC_LINKING)
        SET(CMAKE_EXE_LINKER_FLAGS "-static")
        SET_TARGET_PROPERTIES(${exampleBin} PROPERTIES LINK_SEARCH_END_STATIC 1)
    ENDIF(STATIC_LINKING)

    IF (BUILD_SHARED_LIBS)
      ADD_DEPENDENCIES(${exampleBin} quacode)
      ADD_DEPENDENCIES(${exampleBin} sibus)
    ENDIF()
  ENDFOREACH ()

  # Add targets for examples which need threads
  IF (SIBUS_THREAD)
    FOREACH (example ${SIBUS_EXAMPLES_SRCS_NEED_THREADS})
      GET_FILENAME_COMPONENT(exampleBin ${example} NAME_WE)
      ADD_EXECUTABLE(${exampleBin} ${example})
      TARGET_LINK_LIBRARIES(${exampleBin} ${QCSP_LIB} ${SIBUS_LIBS} ${GECODE_LIBRARIES} pthread)

      # set -static, when STATIC_LINKING is TRUE and set LINK_SEARCH_END_STATIC
      # to remove the additional -Bdynamic from the linker line.
      IF(STATIC_LINKING)
          SET(CMAKE_EXE_LINKER_FLAGS "-static")
          SET_TARGET_PROPERTIES(${exampleBin} PROPERTIES LINK_SEARCH_END_STATIC 1)
      ENDIF(STATIC_LINKING)

      IF (BUILD_SHARED_LIBS)
        ADD_DEPENDENCIES(${exampleBin} quacode)
        ADD_DEPENDENCIES(${exampleBin} sibus)
      ENDIF()
    ENDFOREACH ()
  ENDIF()

  # ENDIF(NOT GECODE_FOUND)
