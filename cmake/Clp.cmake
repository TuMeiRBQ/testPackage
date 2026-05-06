# ============================
# User configurable
# ============================

set(CLP_ROOT "${CMAKE_CURRENT_LIST_DIR}/../third-party/Clp" CACHE PATH "CLP install root")
# ============================
# Validation
# ============================
if(NOT EXISTS "${CLP_ROOT}")
    message(FATAL_ERROR "CLP_ROOT does not exist: ${CLP_ROOT}")
endif()

set(CLP_INCLUDE_DIR "${CLP_ROOT}/include")
set(CLP_LIB_DIR "${CLP_ROOT}/lib")

if(NOT EXISTS "${CLP_INCLUDE_DIR}")
    message(FATAL_ERROR "CLP include dir not found: ${CLP_INCLUDE_DIR}")
endif()

if(NOT EXISTS "${CLP_LIB_DIR}")
    message(FATAL_ERROR "CLP lib dir not found: ${CLP_LIB_DIR}")
endif()

# ============================
# Imported targets
# ============================

add_library(CLP::CoinUtils SHARED IMPORTED)
set_target_properties(CLP::CoinUtils PROPERTIES
    IMPORTED_LOCATION "${CLP_LIB_DIR}/libCoinUtils.so"
    INTERFACE_INCLUDE_DIRECTORIES "${CLP_INCLUDE_DIR}"
)

add_library(CLP::Osi SHARED IMPORTED)
set_target_properties(CLP::Osi PROPERTIES
    IMPORTED_LOCATION "${CLP_LIB_DIR}/libOsi.so"
    INTERFACE_INCLUDE_DIRECTORIES "${CLP_INCLUDE_DIR}"
    INTERFACE_LINK_LIBRARIES CLP::CoinUtils
)

add_library(CLP::Clp SHARED IMPORTED)
set_target_properties(CLP::Clp PROPERTIES
    IMPORTED_LOCATION "${CLP_LIB_DIR}/libClp.so"
    INTERFACE_INCLUDE_DIRECTORIES "${CLP_INCLUDE_DIR}"
    INTERFACE_LINK_LIBRARIES "CLP::CoinUtils;CLP::Osi"
)

add_library(CLP::OsiClp SHARED IMPORTED)
set_target_properties(CLP::OsiClp PROPERTIES
    IMPORTED_LOCATION "${CLP_LIB_DIR}/libOsiClp.so"
    INTERFACE_INCLUDE_DIRECTORIES "${CLP_INCLUDE_DIR}"
    INTERFACE_LINK_LIBRARIES "CLP::Clp"
)

# Aggregate target
add_library(CLP::CLP INTERFACE IMPORTED)

set_target_properties(CLP::CLP PROPERTIES
    INTERFACE_LINK_LIBRARIES "CLP::OsiClp"
)