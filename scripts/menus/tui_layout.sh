#!/bin/sh
# Copyright (C) ShellEasytier
# TUI 界面布局库

# 设置菜单总宽度
TABLE_WIDTH=60

# 预定义超长模板字符串
FULL_EQ="===================================================================================================="
FULL_DASH="- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - "

# 打印内容行（支持中文自动换行和ANSI颜色）
content_line() {
    raw_input="$1"

    if [ -z "$raw_input" ]; then
        printf " \033[%dG||\n" "$TABLE_WIDTH"
        return
    fi

    printf '%b' "$raw_input" | LC_ALL=C awk -v table_width="$TABLE_WIDTH" '
       BEGIN {
           textWidth = table_width - 3
           currentDisplayWidth = 0
           wordWidth = 0
           currentLine = ""
           wordBuffer = ""
           lastColor = ""
           savedColor = ""
           ESC = sprintf("%c", 27)
       }

       {
           n = split($0, chars, "")
           for (i = 1; i <= n; i++) {
               r = chars[i]
               if (r == ESC && i+1 <= n && chars[i+1] == "[") {
                   ansiSeq = ""
                   for (j = i; j <= n; j++) {
                       ansiSeq = ansiSeq chars[j]
                       if (chars[j] == "m") {
                           i = j
                           break
                       }
                   }
                   wordBuffer = wordBuffer ansiSeq
                   lastColor = ansiSeq
                   continue
               }

               charWidth = 1
               if (r <= "\177") { charWidth = 1 }
               else if (r >= "\340" && r <= "\357" && i+2 <= n) {
                   r = chars[i] chars[i+1] chars[i+2]
                   i += 2
                   charWidth = 2
               }
               else if (r >= "\300" && r <= "\337" && i+1 <= n) {
                   r = chars[i] chars[i+1]
                   i += 1
                   charWidth = 1
               }

               if (r == " " || charWidth == 2) {
                   if (currentDisplayWidth + wordWidth + charWidth > textWidth) {
                       printf " %s\033[0m\033[%dG||\n", currentLine, table_width
                       currentLine = savedColor wordBuffer
                       currentDisplayWidth = wordWidth
                       wordBuffer = r
                       wordWidth = charWidth
                       savedColor = lastColor
                   } else {
                       currentLine = currentLine wordBuffer r
                       currentDisplayWidth += wordWidth + charWidth
                       wordBuffer = ""
                       wordWidth = 0
                       savedColor = lastColor
                   }
               } else {
                   wordBuffer = wordBuffer r
                   wordWidth += charWidth
                   if (wordWidth > textWidth) {
                       printf " %s%s\033[0m\033[%dG||\n", currentLine, wordBuffer, table_width
                       currentLine = savedColor
                       currentDisplayWidth = 0
                       wordBuffer = ""
                       wordWidth = 0
                       savedColor = lastColor
                   }
               }
           }

           if (wordWidth > 0) {
               if (currentDisplayWidth + wordWidth > textWidth) {
                   printf " %s\033[0m\033[%dG||\n", currentLine, table_width
                   currentLine = savedColor wordBuffer
               } else {
                   currentLine = currentLine wordBuffer
               }
           }

           printf " %s\033[0m\033[%dG||\n", currentLine, table_width

           currentLine = lastColor
           currentDisplayWidth = 0
           wordBuffer = ""
           wordWidth = 0
           savedColor = lastColor
       }
       END {}
       '
}

# 打印子内容行（用于说明文字）
sub_content_line() {
    param="$1"
    if [ -z "$param" ]; then
        printf " \033[%dG||\n" "$TABLE_WIDTH"
        return
    fi
    content_line "   $param"
    printf " \033[%dG||\n" "$TABLE_WIDTH"
}

# 打印分隔线
# 参数 $1: "=" 或 "-"
separator_line() {
    separatorType="$1"
    lenLimit=$((TABLE_WIDTH - 1))
    outputLine=""
    if [ "$separatorType" = "=" ]; then
        outputLine=$(printf "%.${lenLimit}s" "$FULL_EQ")
    else
        outputLine=$(printf "%.${lenLimit}s" "$FULL_DASH")
    fi
    printf "%s||\n" "$outputLine"
}

# 空行（增加可读性）
line_break() {
    printf "\n\n"
}
