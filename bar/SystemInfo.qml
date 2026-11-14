pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  property string cpuUsage: "0%"
  property string memoryUsage: "0%"
  property string networkInfo: "Disconnected"
  property string networkType: "disconnected"
  property int batteryLevelRaw: 0
  property string batteryLevel: "0%"
  property string batteryIcon: "󰂎"
  property bool batteryCharging: false
  property string temperature: "0°C"

  property double _prevCpuTotal: 0
  property double _prevCpuIdle: 0
  property bool _hasPrevCpuSample: false

  // CPU Usage (from /proc/stat, no external dependencies)
  Process {
    id: cpuProc
    command: ["sh", "-c", "head -n 1 /proc/stat"]
    running: true

    stdout: StdioCollector {
      onStreamFinished: {
        const parts = text.trim().split(/\s+/)
        if (parts.length < 5 || parts[0] !== "cpu") {
          return
        }

        const user = parseInt(parts[1], 10) || 0
        const nice = parseInt(parts[2], 10) || 0
        const system = parseInt(parts[3], 10) || 0
        const idle = parseInt(parts[4], 10) || 0
        const iowait = parseInt(parts[5], 10) || 0
        const irq = parseInt(parts[6], 10) || 0
        const softirq = parseInt(parts[7], 10) || 0
        const steal = parseInt(parts[8], 10) || 0

        const idleAll = idle + iowait
        const total = user + nice + system + idle + iowait + irq + softirq + steal

        if (root._hasPrevCpuSample) {
          const totalDiff = total - root._prevCpuTotal
          const idleDiff = idleAll - root._prevCpuIdle
          if (totalDiff > 0) {
            const usage = (1 - idleDiff / totalDiff) * 100
            root.cpuUsage = Math.max(0, Math.min(100, usage)).toFixed(1) + "%"
          }
        }

        root._prevCpuTotal = total
        root._prevCpuIdle = idleAll
        root._hasPrevCpuSample = true
      }
    }
  }

  // Memory Usage
  Process {
    id: memProc
    command: ["sh", "-c", "free | grep Mem | awk '{printf \"%.1f%%\", ($3/$2) * 100.0}'"]
    running: true

    stdout: StdioCollector {
      onStreamFinished: {
        root.memoryUsage = text.trim()
      }
    }
  }

  // Network Info (ethernet takes priority over wifi)
  Process {
    id: netProc
    command: ["sh", "-c", "eth=$(nmcli -t -f type,state dev 2>/dev/null | grep '^ethernet:connected'); if [ -n \"$eth\" ]; then echo 'ethernet:Ethernet'; else wifi=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2); if [ -n \"$wifi\" ]; then echo \"wifi:$wifi\"; else echo 'disconnected:'; fi; fi"]
    running: true

    stdout: StdioCollector {
      onStreamFinished: {
        const result = text.trim()
        const colonIdx = result.indexOf(':')
        const type = result.substring(0, colonIdx)
        const info = result.substring(colonIdx + 1)
        root.networkType = type
        root.networkInfo = info || "Disconnected"
      }
    }
  }

  // Battery
  Process {
    id: batteryProc
    command: ["sh", "-c", "printf '%s\\n%s' \"$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null || echo '99')\" \"$(cat /sys/class/power_supply/BAT*/status 2>/dev/null || echo 'Discharging')\""]
    running: true

    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.trim().split("\n")
        const level = parseInt(lines[0]) || 0
        const status = (lines[1] || "Discharging").trim()

        root.batteryLevelRaw = level
        root.batteryLevel = level + "%"
        root.batteryCharging = status === "Charging"

        if (root.batteryCharging) root.batteryIcon = ""
        else if (level >= 90) root.batteryIcon = "󰁹"
        else if (level >= 80) root.batteryIcon = "󰂂"
        else if (level >= 70) root.batteryIcon = "󰂁"
        else if (level >= 60) root.batteryIcon = "󰂀"
        else if (level >= 50) root.batteryIcon = "󰁿"
        else if (level >= 40) root.batteryIcon = "󰁾"
        else if (level >= 30) root.batteryIcon = "󰁽"
        else if (level >= 20) root.batteryIcon = "󰁼"
        else if (level >= 10) root.batteryIcon = "󰁻"
        else root.batteryIcon = "󰁺"
      }
    }
  }

  // Temperature
  Process {
    id: tempProc
    command: ["sh", "-c", "sensors 2>/dev/null | grep -E 'Package id 0|Tctl' | head -1 | awk '{print $2}' | sed 's/+//' || echo 'N/A'"]
    running: true

    stdout: StdioCollector {
      onStreamFinished: {
        root.temperature = text.trim() || "N/A"
      }
    }
  }

  // Update timer
  Timer {
    interval: 2000
    running: true
    repeat: true
    onTriggered: {
      cpuProc.running = true
      memProc.running = true
      netProc.running = true
      batteryProc.running = true
      tempProc.running = true
    }
  }
}
