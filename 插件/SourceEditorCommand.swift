//
//  SourceEditorCommand.swift
//  插件
//
//  Created by Devin on 2017/11/6.
//  Copyright © 2017年 Devin. All rights reserved.
//

import Foundation
import XcodeKit

class SourceEditorCommand: NSObject, XCSourceEditorCommand {
    
    
    private let classString = "class "
    
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        // Implement your command here, invoking the completion handler when done. Pass it nil on success, and an NSError on failure.
    
        // 获取光标所在位置的范围
        let selection = invocation.buffer.selections.firstObject as? XCSourceTextRange
        // 当前文件每行显示的内容
        let lines = invocation.buffer.lines
        let linesStr = lines.map{$0 as! String}
        
        guard selection != nil else {
            completionHandler(nil)
            return
        }
        
        // 获取类名
        let ownfileName = fileName(selection: selection!, comment: linesStr)
        // 插入代码 var
        lines.insert(insertVarCode(), at: selectionFileName(selection: selection!, comment: linesStr).classLine)
        // 光标处 插入代码
        lines.insert(insertSelectionCode(), at: selection!.end.line)
        
        // 尾部拼接代理
        if ownfileName != nil {
            lines.addObjects(from: insertEndCode(ownfileName!))
        }
        
        completionHandler(nil)
    }
    
}


extension SourceEditorCommand {
    /// 获取文件名
    /// 规则：1.根据光标所在的位置，获取距离光标上一行代码，最近的`class`
    ///      2.如果没有获取到。则获取第二行 `xxxx.swift` 文本
    ///      3.如果上述都不成立，则为`nil`
    /// - Parameters:
    ///   - selection: XCSourceTextRange
    ///   - comment: [String]
    /// - Returns: String?
    fileprivate func fileName(selection:XCSourceTextRange, comment: [String]) -> String? {
        let secondLine = comment[1]
        var filename:String?
        filename = selectionFileName(selection: selection, comment: comment).className ?? headerFileName(fromFileNameComment: secondLine)
        return filename
    }
    
    // "//  Classname.swift" -> "Classname"
    fileprivate func headerFileName(fromFileNameComment comment: String) -> String? {
        
        let comment = comment.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let commentPrefix = "//"
        guard comment.hasPrefix(commentPrefix) else { return nil }
        
        let swiftExtensionSuffix = ".swift"
        guard comment.hasSuffix(swiftExtensionSuffix) else { return nil }
        
        let startIndex = comment.index(comment.startIndex, offsetBy: commentPrefix.characters.count)
        let endIndex = comment.index(comment.endIndex, offsetBy: -swiftExtensionSuffix.characters.count)
        
        return comment[startIndex..<endIndex].trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    fileprivate func selectionFileName(selection:XCSourceTextRange, comment: [String]) -> (className:String?, classLine:Int) {
        var ownfileName:String?
        var classIndex = 0
        // 获取当前光标上面所在最近的类
        guard selection.end.line > 0 else {
            return (nil,classIndex)
        }
        let selectionEnd = selection.end.line - 1
        guard selectionEnd < comment.count else {
            return (nil,classIndex)
        }
        let selectionBefore = comment[0...selectionEnd]
        for (index,element) in selectionBefore.reversed().enumerated() {
            if element.hasPrefix(classString) {
                classIndex = selectionBefore.count - index
                // 去掉 classString
                var newElement = element.replacingOccurrences(of: classString, with: "")
                // 去掉 \n
                newElement = newElement.trimmingCharacters(in: .whitespacesAndNewlines)
                // 去掉 空格
                newElement = newElement.replacingOccurrences(of: " ", with: "")
                let nsNewElement = newElement as NSString
                if newElement.contains(":") {
                    let getRange = nsNewElement.range(of: ":")
                    ownfileName = nsNewElement.substring(to: getRange.location)
                }else if newElement.contains("{") {
                    let getRange = nsNewElement.range(of: "{")
                    ownfileName = nsNewElement.substring(to: getRange.location)
                }else {
                    ownfileName = newElement
                }
                break
            }
        }
        return (ownfileName,classIndex)
    }
}

extension SourceEditorCommand {
    
    fileprivate func insertSelectionCode() -> String {
        let result = """
        \t\tmainTableView.register(<#T##cellClass: AnyClass?##AnyClass?#>, forCellReuseIdentifier: <#T##String#>)
        \t\tmainTableView.register(<#T##nib: UINib?##UINib?#>, forCellReuseIdentifier: <#T##String#>)
        \t\tview.addSubview(mainTableView)
        """
        return result
    }
    
    fileprivate func insertVarCode() -> String {
        let result = """
        \n
        \tlazy var mainTableView:UITableView = {
        \t\tvar mainTableView = UITableView(frame: <#T##CGRect#>, style: <#T##UITableViewStyle#>)
        \t\tmainTableView.dataSource = self
        \t\tmainTableView.delegate = self
        \t\tmainTableView.tableFooterView = UIView()
        \t\tmainTableView.separatorStyle = .none
        \t\treturn mainTableView
        \t}()
        \n
        """
        return result
    }
    
    
    fileprivate func insertEndCode(_ className:String) -> [String] {
        let result = """
        \n
        extension \(className): UITableViewDataSource, UITableViewDelegate {
            
        \t// MARK: - UITableViewDataSource
        \tfunc tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        \t\t<#code#>
        \t}
            
        \tfunc tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        \t\t<#code#>
        \t}
            
        \tfunc numberOfSections(in tableView: UITableView) -> Int {
        \t\t<#code#>
        \t}
            
        \t// MARK: - UITableViewDelegate
        \tfunc tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        \t\t<#code#>
        \t}
            
        \tfunc tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        \t\t<#code#>
        \t}
        }
        """
        return [result]
    }
}
