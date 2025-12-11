# -*- coding: utf-8 -*-
'''
Note:
- xlsx only supports xlrd 1.2.0
- TODO: when first row is not empty, generate empty table
- TODO: handle empty name field
'''
import sys
import io

def _force_gbk(stream):
    try:
        stream.reconfigure(encoding='gbk', errors='ignore')
        return stream
    except AttributeError:
        buffer = getattr(stream, "buffer", None)
        if buffer:
            return io.TextIOWrapper(buffer, encoding='gbk', errors='ignore', line_buffering=True)
        return stream
    except Exception:
        return stream

sys.stdout = _force_gbk(sys.stdout)
sys.stderr = _force_gbk(sys.stderr)

if sys.version_info < (3, 0):
    print('python version need more than 3.x')
    sys.exit(1)

import os
import getopt
import xlrd
import json

KIND_NORMAL = "normal"
KIND_GLOBAL = "global"

READ_FILE_TYPE = {".xlsx"}

TARGET_FILE_TYPE = {
    "j": ["json"],
    "l": ["lua"],
    "jl":["json", "lua"],
}
TARGET_FILE_USE = {"c", "s"}
TAGET_FILE_HEADN_INFO = {
    "lua": [
        '-- author:   liter_wave ' +
        '\n-- Automatic generation from -->>' +
        '\n-- excel file  name: {0}' +
        '\n-- excel sheet name: {1}\n'
    ],
    "json": [
        ''
    ]
}

PREFIX = "table = "

FORMAT_FUNC = {
    "str": lambda x: str(x),
    "int": lambda x: int(float(x)),
    "arrstr": lambda x: [i.strip() for i in x.split(',')],
    "array": lambda x: [int(i.strip()) for i in x.split(',')],
    "list": lambda x: list(eval(x)),
    "table": lambda x: PREFIX + str(x),
}

FORMAT_DEFAULT_VALUE = {
    "str": "",
    "int": 0,
    "arrstr": [],
    "array": [],
    "list": [],
    "table": {}
}


def toLua(dealInfoMap):
    out = []
    _ToLua(out, dealInfoMap)
    luaStr = "".join(out)
    outStr = 'return %s' % luaStr
    return outStr

def toJson(dealInfoMap):
    return json.dumps(dealInfoMap, sort_keys=True, indent=4, ensure_ascii=False)


SUPPORT_TARGET_TYPE = {
    "lua": toLua,
    "json": toJson
}


def _ToLua(out, obj, indent=1):
    if isinstance(obj, int) or isinstance(obj, float):
       out.append(json.dumps(obj, ensure_ascii = False))
    elif(isinstance(obj, str)):
        if obj.find(PREFIX) == 0:
            out.append(obj[len(PREFIX):])
        else:
            out.append(json.dumps(obj, ensure_ascii = False))
    else:
        isList = isinstance(obj, list)
        out.append('{')
        isFirst = True
        for i in obj:
            if isFirst:
                isFirst = False
            else:
                out.append(',')
            out.append(_NewLine(indent))
            if not isList:
                # obj[i] 
                k = i
                i = obj[k]
                out.append('[')
                if isinstance(k, int) or isinstance(k, float):
                    out.append(str(k))
                else:
                    out.append('"')
                    out.append(str(k))
                    out.append('"')
                out.append(']')
                out.append(' = ')
            _ToLua(out, i, indent + 1)
        out.append(_NewLine(indent - 1))
        out.append('}')


def _NewLine(count):
    return '\n' + '    ' * count


'''
-d set excel config directory
-f set output file type
-t set output directory
'''


def usage():
    """
    shell use
    :return:
    """
    print("""
            -h help
            -d set directory
            -f set file type
            -t set target directory
            -o set only for client or server
""")


class genConfig():
    """
    Excel file meta info
    """
    def __init__(self):
        """
        -r excel config file
        -f output file type
        -t output directory
        -o target side (c/s), used by 3rd row in excel
        """
        self.excelPathFile = None
        self.fileType = None
        self.targetDir = None
        self.sheets = None
        self.useType = None
        self.excelBasename = None
        self.excelfileName = None
        self.useDefaultVal = None

    def canStart(self):
        if not self.excelPathFile:
            return
        if not self.fileType:
            return
        if not self.targetDir:
            return
        if not self.sheets:
            return
        if not self.useType:
            return
        if not self.excelBasename:
            return
        if not self.excelfileName:
            return
        return True


    def setExcelFile(self, excelFile):
        """
        Set excel file path
        :param excelFile: excel file path
        :return:
        """
        _, extension = os.path.splitext(excelFile)
        if extension not in READ_FILE_TYPE:
            print("not excel file")
            sys.exit(1)
        excelFileDir, excelFilename = os.path.split(excelFile)
        self.excelPathFile = excelFile
        self.excelBasename = excelFileDir
        self.excelfileName = excelFilename

        self.getSheets()

    def setFileType(self, fileType="lua"):
        """
        Set output file type, default is lua
        :param FileType: file type
        :return:
        """
        if not TARGET_FILE_TYPE[fileType]:
            print("not support file type")
            sys.exit(1)
        self.fileType = fileType

    def setTargetDir(self, targetDir):
        """
        Set output directory
        :param excelFile:
        :return:
        """
        if not os.path.exists(targetDir):
            os.makedirs(targetDir)
        self.targetDir = targetDir

    def getSheets(self):
        """
        Read sheets from excel
        :return:
        """
        excelObj = xlrd.open_workbook(self.excelPathFile)
        self.sheets = excelObj.sheets()
        # debug only
        self.debugSheet()

    def debugSheet(self):
        """
        Debug: check sheets
        :return:
        """
        # check sheet name
        for sheet in self.sheets:
            print(sheet.name)

    def setOTargetUse(self, UseType):
        """
        Check use type (client/server)
        :param UseType: use type
        :return:
        """
        if UseType not in TARGET_FILE_USE:
            print("set for client or server or all")
            sys.exit(1)
        self.useType = UseType


class dealExcelInfo():

    def __init__(self, genConfig):
        self.genConfig = genConfig
        self.dealExcel()

    def initData(self):
        self.dealInfoMap = dict()
        self.saveColInfoList = list()
        self.targetInfoMap = dict()

    def dealExcel(self):
        """
        Handle excel file
        :return:
        """
        for sheet in self.genConfig.sheets:
            self.initData()
            self.dealCol(sheet)
            self.dealBody(sheet)
            self.debugDealExcel()
            self.export(sheet)

    def dealCol(self, sheet):
        """
        Handle sheet columns, such as value type and target side
        :param sheet: excel sheet object
        :return:
        """
        # row1: description, row2: data type, row3: field name, row4: use type (c/s)
        if sheet.nrows < 4:
            print("error:{0} directory:{1}".format(sheet.name, self.genConfig.excelPathFile))
            sys.exit(1)
        # dataType such as int table ...
        dataTypes = sheet.row_values(1)
        # field name
        names = sheet.row_values(2)
        # output file such as for client or server
        useTypes = sheet.row_values(3)

        for colIndex in range(sheet.ncols):
            dataType = str(dataTypes[colIndex]).strip()
            name = str(names[colIndex]).strip()
            isUseType = self.isUseType(str(useTypes[colIndex]).strip(), self.genConfig.useType.strip())

            if self.checkDataType(dataType):
                print("dir：{0} at {1}, not fileType:{2},column:{3}".format(self.genConfig.excelPathFile, sheet.name,
                                                                     dataType, name))
                sys.exit(1)

            self.saveColInfoList.append((dataType, name, isUseType))

    def isUseType(self, useType, oUseType):
        """
        Check whether to generate specific useType columns
        :param useType: use type of config
        :param oUseType: target use type
        :return:
        """
        if oUseType in useType.split('/'):
            return True
        return False

    def checkDataType(self, dataType):
        """
        Check data type
        :param dataType: data type
        :return:
        """
        if dataType in FORMAT_FUNC:
            return False
        return True

    def dealBody(self, sheet):
        """
        Handle empty data: generate empty file instead of exit
        :return:
        """
        # From row 5, we start to read data rows
        for rowIndex in range(4, sheet.nrows):
            row = sheet.row_values(rowIndex, 0, sheet.ncols)
            if not self.getValue(row, 0):
                # skip row when first column is empty
                print("dir: {0} at {1}, skip row {2} (first column empty)".format(self.genConfig.excelPathFile, sheet.name,
                                                                     rowIndex + 1))
                continue
            print("sheet.ncols", sheet.ncols)
            print(self.saveColInfoList)
            for colIndex in range(1, sheet.ncols):
                print("colIndex: ", colIndex)
                print("self.saveColInfoList[colIndex][2]", self.saveColInfoList[colIndex][2])
                if not self.saveColInfoList[colIndex][2]:
                    continue
                value = self.getValue(row, colIndex)
                name = self.saveColInfoList[colIndex][1]
                if not self.dealInfoMap.get(self.getValue(row, 0)):
                    self.dealInfoMap[self.getValue(row, 0)] = dict()
                print("value = self.getValue(row, colIndex)", value)
                print("name", name)
                if value:
                    self.dealInfoMap[self.getValue(row, 0)][name] = value

    def getValue(self, row, colIndex):
        dataType = self.saveColInfoList[colIndex][0]
        name = self.saveColInfoList[colIndex][1]
        value = str(row[colIndex]).strip()
        if name and value:
            if name =="num":
                print(FORMAT_FUNC[dataType](value))
            print(colIndex, row, dataType, name, value)
            formatFunc = FORMAT_FUNC[dataType]
            return formatFunc(value)
        if colIndex == 0:
            return None
        if self.genConfig.useDefaultVal:
            return FORMAT_DEFAULT_VALUE[dataType]

    def export(self, sheet):
        fileTypeList = TARGET_FILE_TYPE[self.genConfig.fileType]
        for fileType in fileTypeList:
            transFunc = SUPPORT_TARGET_TYPE[fileType]
            outStr = self.outNote(sheet, fileType) + transFunc(
            self.dealInfoMap)
            # save to file
            targetFile = self.genConfig.targetDir + '/' + sheet.name + '.' + fileType
            print("test", targetFile)
            print("outStr: ", outStr)
            print("self.dealInfoMap: ", self.dealInfoMap)
            with open(targetFile, 'w') as f:
                f.write(outStr + "\n")

    def outNote(self, sheet, fileType):
        return "".join(TAGET_FILE_HEADN_INFO[fileType]).format(self.genConfig.excelPathFile, sheet.name)

    def debugDealExcel(self):
        print(self.saveColInfoList)
        print(self.dealInfoMap)


if __name__ == '__main__':
    # excel file info
    genConfig = genConfig()
    print("gen_data start")
    try:
        opst, args = getopt.getopt(sys.argv[1:], 'r:f:t:h:o:')
    except:
        usage()
        sys.exit(1)

    for op, v in opst:
        if op == "-h":
            usage()
        elif op == "-r":
            # 设置excel配置路径
            genConfig.setExcelFile(v)
        elif op == "-f":
            # 指定输出的文件类型
            genConfig.setFileType(v)
        elif op == "-t":
            # 文件生成后的存的path
            genConfig.setTargetDir(v)
        elif op == "-o":
            # target side: client or server
            genConfig.setOTargetUse(v)
    if not genConfig.canStart():
        print("arg error")
        usage()
        sys.exit(1)
    
    dealExcel = dealExcelInfo(genConfig)
