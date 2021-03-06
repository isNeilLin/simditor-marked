((factory)->
  if (typeof define is 'function') and define.amd
    define ['simditor', 'marked'], factory
  else
    factory window.Simditor, window.marked
)((Simditor, _marked)->
  class MarkedButton extends Simditor.Button
    constructor: ->
      super
      @marked = _marked
      throw new Error('cannot find the plugin marked') if not _marked

    _init: ->
      if @editor.util.os.mac
        @title = @title + ' ( Cmd + m )'
      else
        @title = @title + ' ( Ctrl + m )'
        @shortcut = 'ctrl+m'
      super
      @setIcon("maxcdn")

    name: 'marked'
    title: 'marked'
    icon: 'maxcdn'
    shortcut: 'cmd+m'

    setIcon: (icon)->
      @el.find("span").removeClass().addClass("fa fa-#{icon}")
    #反转义字符串
    decodeHTML: (str)->
      div = document.createElement('div')
      div.innerHTML = str
      div.innerText or div.textContent

    #转义字符串
    encodeHTML: (str)->
      div = document.createElement('div')
      div.appendChild document.createTextNode str
      div.innerHTML

    #反转义所有code标签里面的字符
    decodeCodes: (content)->
      div = document.createElement 'div'
      div.innerHTML = content
      codes = div.querySelectorAll 'code'
      for code in codes
        text = @decodeHTML(code.innerText or div.textContent)
        code.innerText = text if code.innerText
        code.textContent = text if code.textContent

      return div.innerHTML


    ## 替换选中文字
    ## 代码来自 http://stackoverflow.com/questions/5393922/javascript-replace-selection-all-browsers
    ## 删除了一部分关于ie8的兼容代码，并改写成了coffee
    replaceSelection: (html, selectInserted = true)->
      sel = window.getSelection()
      # Test that the Selection object contains at least one Range
      return if not (sel.getRangeAt && sel.rangeCount)
      range = window.getSelection().getRangeAt(0)
      range.deleteContents()
      if range.createContextualFragment
        fragment = range.createContextualFragment html
      else
        div = document.createElement "div"
        div.innerHTML = html
        fragment = document.createDocumentFragment()
        fragment.appendChild child while (child = div.firstChild)

      firstInsertedNode = fragment.firstChild
      lastInsertedNode = fragment.lastChild
      range.insertNode fragment

      return if not selectInserted
      if firstInsertedNode
        range.setStartBefore firstInsertedNode
        range.setEndAfter lastInsertedNode
      sel.removeAllRanges()
      sel.addRange range

    doReplaceSelction: (sel)->
      value = @marked @encodeHTML sel
      value = @decodeCodes value
      @replaceSelection value

    doReplaceAll: ()->
      value = @editor.getValue()
      value = value.replace(/<p>/g, '').replace(/<\/p>/g, '\n')
      value = @marked value
      value = @decodeCodes value
      @editor.setValue value

    command: ()->
      sel = window.getSelection().toString()
      if sel.length is 0 then @doReplaceAll() else @doReplaceSelction(sel)
      @editor.selection.setRangeAtEndOf('p')

  Simditor.Toolbar.addButton(MarkedButton)
)