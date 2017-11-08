//
//  SourceEditorExtension.swift
//  插件
//
//  Created by Devin on 2017/11/6.
//  Copyright © 2017年 Devin. All rights reserved.
//

import Foundation
import XcodeKit

class SourceEditorExtension: NSObject, XCSourceEditorExtension {
    
    /*
    func extensionDidFinishLaunching() {
        // If your extension needs to do any work at launch, implement this optional method.
    }
    */
    
    ///*
    var commandDefinitions: [[XCSourceEditorCommandDefinitionKey: Any]] {
        // If your extension needs to return a collection of command definitions that differs from those in its Info.plist, implement this optional property getter.
        return [
            [.classNameKey : "插件.SourceEditorCommand", // 格式:Target名.Command文件名
                .identifierKey : "com.Devin.XcodeSourceEditorDemo.SourceEditorCommand", // 格式: BundleIdentifier.任意字符串
                 .nameKey : "UITableView"]
                ]
    }
    //*/
    
}
