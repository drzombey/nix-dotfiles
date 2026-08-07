//@ pragma IconTheme Papirus-Dark
//@ pragma ShellId nocturne

import Quickshell
import qs.bar

// Eine Bar pro Monitor.
ShellRoot {
    Variants {
        model: Quickshell.screens

        Bar {
            required property var modelData

            screen: modelData
        }
    }
}
