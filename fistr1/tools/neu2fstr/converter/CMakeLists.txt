###############################################################################
# Copyright (c) 2016 FrontISTR Forum, The University of Tokyo
# This software is released under the MIT License, see License.txt
###############################################################################
cmake_minimum_required(VERSION 2.8.11)

list(APPEND neu2fstr_SOURCES
  ${CMAKE_CURRENT_LIST_DIR}/cconv_mat.cpp
  ${CMAKE_CURRENT_LIST_DIR}/CConvMessage.cpp
  ${CMAKE_CURRENT_LIST_DIR}/conv_neu2hec.cpp
  ${CMAKE_CURRENT_LIST_DIR}/conv_neu2fstr_static.cpp
  ${CMAKE_CURRENT_LIST_DIR}/conv_neu2fstr_dynamic.cpp
  ${CMAKE_CURRENT_LIST_DIR}/conv_neu2fstr_heat.cpp
)

list(APPEND neu2fstr_INCLUDE_DIRS
  ${CMAKE_CURRENT_LIST_DIR}
)

