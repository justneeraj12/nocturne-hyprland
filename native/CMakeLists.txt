cmake_minimum_required(VERSION 3.24)
project(nocturne-native VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 6.6 REQUIRED COMPONENTS Core Gui Qml Quick Network)

qt_standard_project_setup(REQUIRES 6.6)
qt_policy(SET QTP0004 NEW)
qt_add_executable(nocturne-native src/main.cpp src/backend.cpp src/backend.h)
qt_add_qml_module(nocturne-native
    URI Nocturne.Native
    VERSION 1.0
    NO_IMPORT_SCAN
    QML_FILES
        qml/Shell.qml
        qml/Settings.qml
        qml/components/NocturneButton.qml
        qml/components/NocturneSlider.qml
        qml/components/SectionLabel.qml
        qml/pages/AudioPage.qml
        qml/pages/BrightnessPage.qml
        qml/pages/CalendarPage.qml
        qml/pages/WorldPage.qml
        qml/pages/ConnectivityPage.qml
        qml/pages/PomodoroPage.qml
        qml/pages/PowerPage.qml
        qml/pages/CapturePage.qml
)

target_link_libraries(nocturne-native PRIVATE
    Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick Qt6::Network
)

install(TARGETS nocturne-native RUNTIME DESTINATION bin)
