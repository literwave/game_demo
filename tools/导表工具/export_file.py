'''
xlsx 仅仅支持1.2.0 xlrd
1.待做 第一行 数据不为空的时候生成空表就行了
2.name 可能为会空的情况
3.
'''
import sys
from telnetlib import theNULL

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

TARGET_FILE_TYPE = {"py", "json", "lua"}
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


def toLua(dealInfo):
    out = []
    _ToLua(out, dealInfo)
    luaStr = "".join(out)
    outStr = 'return %s' % luaStr
    return outStr


def toJson(dealInfo):
    return json.dumps(dealInfo, sort_keys=True, indent=4, ensure_ascii=False)


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
-d 指定配置表excel目录
-f 指定生成file格式
-t 指定输出文件目录
'''


def Usage():
    """
    shell use
    :return:
    """
    print("usefule")


class excelFileInfo():
    """
    文件信息
    """

    def __init__(self):
        """
        -r 指定配置表excel文件
        -f 指定生成file格式
        -t 指定输出文件目录
        -o 指定生成给客户端还是给服务端的 （作用是第三行的c/s类型）
        """
        self.excelPathFile = None
        self.fileType = None
        self.targetDir = None
        self.sheets = None
        self.useType = None
        self.excelBasename = None
        self.excelfileName = None

    def setExcelFile(self, excelFile):
        """
        设置读取的excel文件
        :param excelFile: excel文件
        :return:
        """
        _, extension = os.path.splitext(excelFile)
        if extension not in READ_FILE_TYPE:
            print("读取的不是excel文件")
            sys.exit(1)
        excelFileDir, excelFilename = os.path.split(excelFile)
        self.excelPathFile = excelFile
        self.excelBasename = excelFileDir
        self.excelfileName = excelFilename

        self.getSheets()

    def setFileType(self, fileType="lua"):
        """
        设置文件类型 默认参数为lua
        :param FileType: 文件类型
        :return:
        """
        if fileType not in TARGET_FILE_TYPE:
            print("不能转行成这种文件格式")
            sys.exit(1)
        self.fileType = fileType

    def setTargetDir(self, targetDir):
        """
        设置生成文件目录
        :param excelFile:
        :return:
        """
        if not os.path.exists(targetDir):
            os.makedirs(targetDir)
        self.targetDir = targetDir

    def getSheets(self):
        """
        读取excel的sheets
        :return:
        """
        excelObj = xlrd.open_workbook(self.excelPathFile)
        self.sheets = excelObj.sheets()
        # 调试专用
        self.debugSheet()

    def debugSheet(self):
        """
        调式检查sheets
        :return:
        """
        # 检查sheetname
        for sheet in self.sheets:
            print(sheet.name)

    def setOTargetUse(self, UseType):
        """
        检查使用在客户端还是服务端
        :param UseType: 使用类型
        :return:
        """
        if UseType not in TARGET_FILE_USE:
            print("请指定生成是给客户端使用还是服务端使用")
            sys.exit(1)
        self.useType = UseType


class dealExcelInfo():

    def __init__(self, excelInfo):
        self.excelInfo = excelInfo

        self.dealInfo = dict()
        self.saveColInfo = list()
        self.targetInfo = dict()
        self.targetFile = ""
        self.dealExcel()

    def dealExcel(self):
        """
        处理excel
        :return:
        """
        for sheet in self.excelInfo.sheets:
            self.dealCol(sheet)
            self.dealBody(sheet)
            self.debugDealExcel()
            self.export(sheet)

    def dealCol(self, sheet):
        """
        处理excel表列的信息，比如值的类型 和 生成前端还是后端
        :param sheet: excel表对象
        :return:
        """
        # 第一行第一列是生成的文件名字 第二行是描述 第三行是数据类型 第四行是生成使用类型(c/s)
        if sheet.nrows < 5:
            print("生成子表出错:{0} 文件路径为：{1}".format(sheet.name, self.excelInfo.excelPathFile))
            sys.exit(1)
            # 第行就是文件描述
        print(self.excelInfo.targetDir)
        self.targetFile = self.excelInfo.targetDir + '/' + sheet.row_values(0)[0] + '.' + self.excelInfo.fileType
        print(self.targetFile)
        dataTypes = sheet.row_values(2)
        names = sheet.row_values(3)
        UseTypes = sheet.row_values(4)

        for colIndex in range(sheet.ncols):
            dataType = str(dataTypes[colIndex]).strip()
            name = str(names[colIndex]).strip()
            IsUseType = self.IsUseType(str(UseTypes[colIndex]).strip(), self.excelInfo.useType.strip())

            if self.checkDataType(dataType):
                print("文件路径为：{0} 在 {1}, 不存在数据类型为:{2},该列为:{3}".format(self.excelInfo.excelPathFile, sheet.sheetName,
                                                                     dataType, name))
                sys.exit(1)

            self.saveColInfo.append((dataType, name, IsUseType))

    def IsUseType(self, useType, oUseType):
        """
        检查是否生成特定使用类型的列
        :param useType: 配置表的生成类型
        :param oUseType: 指定生成类型
        :return:
        """
        if oUseType in useType.split('/'):
            return True
        return False

    def checkDataType(self, dataType):
        """
        检查数据类型
        :param dataType: 数据类型
        :return:
        """
        if dataType in FORMAT_FUNC:
            return False
        return True

    def dealBody(self, sheet):
        """
        需要处理不填数据 生成空文件，而不是终止
        :return:
        """
        # 从第五行开始就是需要的数据了
        for rowIndex in range(5, sheet.nrows):
            row = sheet.row_values(rowIndex)
            if not self.GetSheetValue(row, 0):
                # 跳过一行，没填这行第一列
                print("文件路径为：{0} 在 {1}, 跳过这一行 第{2}行 请检查这行第一列".format(self.excelInfo.excelPathFile, sheet.name,
                                                                     rowIndex + 1))
                continue
            for colIndex in range(1, sheet.ncols):
                if not self.saveColInfo[colIndex][2]:
                    continue
                value = self.GetSheetValue(row, colIndex)
                name = self.saveColInfo[colIndex][1]
                if not self.dealInfo.get(self.GetSheetValue(row, 0)):
                    self.dealInfo[self.GetSheetValue(row, 0)] = dict()

                self.dealInfo[self.GetSheetValue(row, 0)][name] = value

    def GetSheetValue(self, row, colIndex):
        DataType = self.saveColInfo[colIndex][0]
        name = self.saveColInfo[colIndex][1]
        value = str(row[colIndex]).strip()
        if name and value:
            if name =="num":
                print(FORMAT_FUNC[DataType](value))
            formatFunc = FORMAT_FUNC[DataType]
            return formatFunc(value)
        if colIndex == 0:
            return None
        return FORMAT_DEFAULT_VALUE[DataType]

    def export(self, sheet):
        transFunc = SUPPORT_TARGET_TYPE[self.excelInfo.fileType]
        outStr = self.out_note(sheet) + transFunc(
            self.dealInfo)
        # save to file
        print(self.targetFile)
        with open(self.targetFile, 'w') as f:
            f.write(outStr + "\n")

    def out_note(self, sheet):
        return "".join(TAGET_FILE_HEADN_INFO[self.excelInfo.fileType]).format(self.excelInfo.excelPathFile, sheet.name)

    def debugDealExcel(self):
        print(self.saveColInfo)
        print(self.dealInfo)


if __name__ == '__main__':
    # exccel 文件信息
    excelFileInfo = excelFileInfo()

    try:
        opst, args = getopt.getopt(sys.argv[1:], 'r:f:t:h:o:')
    except:
        Usage()
        sys.exit(1)

    for op, v in opst:
        if op == "-h":
            Usage()
        elif op == "-r":
            # 设置excel配置路径
            excelFileInfo.setExcelFile(v)
        elif op == "-f":
            # 指定输出的文件类型
            excelFileInfo.setFileType(v)
        elif op == "-t":
            # 文件生成后的存的path
            excelFileInfo.setTargetDir(v)
        elif op == "-o":
            # 指定生成的文件是客户端还是服务端
            excelFileInfo.setOTargetUse(v)
    if excelFileInfo.excelPathFile and excelFileInfo.fileType and excelFileInfo.targetDir and excelFileInfo.sheets and excelFileInfo.useType and excelFileInfo.excelBasename and excelFileInfo.excelfileName:
        dealExcel = dealExcelInfo(excelFileInfo)
