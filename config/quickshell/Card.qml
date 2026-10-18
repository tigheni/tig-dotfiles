import QtQuick

// Rounded tile that every dashboard section sits in.
Rectangle {
    default property alias content: inner.data
    property string title: ""

    radius: 12
    color: Colors.card

    Text {
        id: heading
        visible: parent.title !== ""
        text: parent.title
        color: Colors.outline
        font.family: Colors.font
        font.pixelSize: 10
        font.letterSpacing: 1
        anchors { top: parent.top; left: parent.left; topMargin: 10; leftMargin: 12 }
    }

    Item {
        id: inner
        anchors {
            fill: parent
            margins: 12
            topMargin: heading.visible ? 28 : 12
        }
    }
}
