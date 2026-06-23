## remove Qt dependencies
QT       -= core gui
CONFIG -= qt

QMAKE_PROJECT_DEPTH = 0

## global defintions : target lib name, version
TARGET = simplest
VERSION=1.6.0
PROJECTDEPLOYDIR = $${PWD}/deploy

DEFINES += MYVERSION=$${VERSION}
CONFIG += c++1z
CONFIG += console

CONFIG += externaldeps

include(findremakenrules.pri)

CONFIG(debug,debug|release) {
    DEFINES += _DEBUG=1
    DEFINES += DEBUG=1
}

CONFIG(release,debug|release) {
    DEFINES += _NDEBUG=1
    DEFINES += NDEBUG=1
}

DEPENDENCIESCONFIG = shared install_recurse

PROJECTCONFIG = QTVS

#NOTE : CONFIG as staticlib or sharedlib, DEPENDENCIESCONFIG as staticlib or sharedlib, QMAKE_TARGET.arch and PROJECTDEPLOYDIR MUST BE DEFINED BEFORE templatelibconfig.pri inclusion
include ($$shell_quote($$shell_path($${QMAKE_REMAKEN_RULES_ROOT}/templateappconfig.pri)))  # Shell_quote & shell_path required for visual on windows

HEADERS += \

SOURCES += \
    main.cpp

unix {
    LIBS += -ldl
    QMAKE_CXXFLAGS += -Wno-attributes

    # Avoids adding install steps manually. To be commented to have a better control over them.
    QMAKE_POST_LINK += "$(MAKE) install install_deps"
}

linux {
    QMAKE_CXXFLAGS += -Werror=switch-enum -Werror=unused-result
}

win32 {

    DEFINES += WIN64 UNICODE _UNICODE
    QMAKE_COMPILER_DEFINES += _WIN64
    QMAKE_CXXFLAGS += -wd4250 -wd4251 -wd4244 -wd4275
}

OTHER_FILES += \
    packagedependencies.txt

#NOTE : Must be placed at the end of the .pro
include ($$shell_quote($$shell_path($${QMAKE_REMAKEN_RULES_ROOT}/remaken_install_target.pri)))) # Shell_quote & shell_path required for visual on windows
