pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

// Notification daemon (org.freedesktop.Notifications). Every notification is kept for
// the notification center until dismissed; new ones are also shown as popups, unless
// "do not disturb" is on (critical ones always are).
Singleton {
    id: root

    // Notification center contents, newest first
    readonly property var list: server.trackedNotifications.values.slice().reverse()
    // Notifications currently shown as popups, oldest first
    property var popups: []
    // Arrival time per notification id; the protocol doesn't carry one
    property var arrivedAt: ({})

    readonly property bool dnd: settings.dnd

    function setDnd(on: bool) {
        settings.dnd = on;
        if (on) popups = popups.filter(n => n?.urgency === NotificationUrgency.Critical);
    }

    function hidePopup(n) {
        popups = popups.filter(p => p && p !== n);
    }

    // A popup ran out: it stays in the center, except transient ones.
    function popupTimedOut(n) {
        hidePopup(n);
        if (n?.transient) n.expire();
    }

    // A short sound for an arriving notification. Detached rather than a managed
    // Process so that several in a row overlap instead of queueing behind each other,
    // and so a missing sound file simply costs nothing.
    function chime(n) {
        // Senders that make their own sound (music players, some messengers) ask for
        // silence with this hint; Quickshell passes the raw hints through.
        if (!Theme.notificationSound || n?.hints?.["suppress-sound"])
            return;
        Quickshell.execDetached(["paplay", Theme.notificationSound]);
    }

    function clearAll() {
        for (const n of server.trackedNotifications.values.slice()) n.dismiss();
        popups = [];
    }

    NotificationServer {
        id: server
        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        actionsSupported: true
        imageSupported: true
        inlineReplySupported: true

        onNotification: n => {
            n.tracked = true;
            root.arrivedAt = Object.assign({}, root.arrivedAt, { [n.id]: new Date() });
            n.closed.connect(() => root.hidePopup(n));
            if (root.dnd && n.urgency !== NotificationUrgency.Critical) return;
            root.popups = [...root.popups.filter(p => p), n];
            root.chime(n);
        }
    }

    // "Do not disturb" survives restarts
    readonly property string stateDir: `${Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state"}/quickshell`

    FileView {
        path: `${root.stateDir}/notifications.json`
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                Quickshell.execDetached(["mkdir", "-p", root.stateDir]);
                writeAdapter();
            }
        }

        JsonAdapter {
            id: settings
            property bool dnd: false
        }
    }

    // qs ipc -c bar call notifications <fn>
    IpcHandler {
        target: "notifications"

        function toggleDnd(): void { root.setDnd(!root.dnd); }
        function clearAll(): void { root.clearAll(); }
    }
}
