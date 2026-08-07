import Foundation

/// 统一日志输出：仅 DEBUG 构建打印到控制台，Release 构建为空操作（避免向用户设备泄露内部信息）。
/// 项目里所有调试日志统一用 `Log(...)`，不再直接调用 `print(...)`。
@inline(__always)
func Log(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    #if DEBUG
    let output = items.map { "\($0)" }.joined(separator: separator)
    Swift.print(output, terminator: terminator)
    #endif
}
