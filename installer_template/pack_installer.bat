del /q ".\packages\com.vendor.product\data\*"
if "%1"=="dbg" (
    echo Building Debug version...
    copy "..\build\Desktop_Qt_6_10_1_MinGW_64_bit-Debug\debug\serialplot.exe" ".\packages\com.vendor.product\data\serialplot.exe"
) else (
    echo Building Release version...
    copy "..\build\Desktop_Qt_6_10_1_MinGW_64_bit-Release\release\serialplot.exe" ".\packages\com.vendor.product\data\serialplot.exe"
)
cd ".\packages\com.vendor.product\data"
copy "C:\Qt\6.10.1\mingw_64\bin\qwt.dll" "."
copy "C:\Qt\6.10.1\mingw_64\bin\Qt6OpenGL.dll" "."
copy "C:\Qt\6.10.1\mingw_64\bin\Qt6OpenGLWidgets.dll" "."
windeployqt serialplot.exe
cd ..\..\..\
binarycreator -c "./config/config.xml" -p "./packages" "serialplot_yssickjgd.exe"
pause