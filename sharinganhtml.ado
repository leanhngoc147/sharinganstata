capture program drop sharinganhtml
program define sharinganhtml, rclass
    version 17.0

    syntax [varlist] [, DIGIT(integer 1) OUTPUT(string) AUTOOPEN ///
        TITLE(string) THEME(string) NOSORT INDENT(string)]

    // Kiểm tra phiên bản Stata
    if !c(version) >= 15 {
        display as error "Chương trình này yêu cầu Stata 15 trở lên."
        exit 199
    }

    cap noi {
        display as text "\t\t███████╗██╗  ██╗ █████╗ ██████╗ ██╗███╗   ██╗ ██████╗  █████╗ ███╗   ██╗  "
        display as text "\t\t██╔════╝██║  ██║██╔══██╗██╔══██╗██║████╗  ██║██╔════╝ ██╔══██╗████╗  ██║  "
        display as text "\t\t███████╗███████║███████║██████╔╝██║██╔██╗ ██║██║  ███╗███████║██╔██╗ ██║  "
        display as text "\t\t╚════██║██╔══██║██╔══██║██╔══██╗██║██║╚██╗██║██║   ██║██╔══██║██║╚██╗██║  "
        display as text "\t\t███████║██║  ██║██║  ██║██║  ██║██║██║ ╚████║╚██████╔╝██║  ██║██║ ╚████║"
        display as text "\t\t╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝"
    }

    local bg_color "#ffffff"
    local text_color "#000000"
    local border_color "#dddddd"
    local header_bg "#f2f2f2"
    local row_alt_bg "#f9f9f9"
    local indent_style ""

    if "`indent'" != "" {
        local indent_style " style='padding-left: `indent'px;'"
    }

    if `digit' < 0 {
        display as error "Digit option must be non-negative"
        exit 198
    }

    if "`varlist'" == "" {
        quietly ds
        local varlist `r(varlist)'
    }

    if "`title'" == "" {
        local title "Báo cáo thống kê mô tả"
    }

    // Xử lý tên file output
    local file_prefix "sharingan"
    local output "`file_prefix'.html"
    local counter 1

    while fileexists("`output'") {
        local output "`file_prefix'_`counter'.html"
        local counter = `counter' + 1
        if `counter' > 999 {
            display as error "Đã tồn tại quá nhiều tệp"
            exit 603
        }
    }

    if "`theme'" == "dark" {
        local bg_color "#2d2d2d"
        local text_color "#ffffff"
        local border_color "#555555"
        local header_bg "#3d3d3d"
        local row_alt_bg "#353535"
    }

    cap file open html_output using "`output'", write replace
    if _rc {
        display as error "Không thể tạo tệp đầu ra"
        exit _rc
    }

    file write html_output ///
        "<!DOCTYPE html>" _n ///
        "<html><head>" _n ///
        "<meta charset='UTF-8'>" _n ///
        "<meta name='viewport' content='width=device-width, initial-scale=1.0'>" _n ///
        "<title>`title'</title>" _n ///
        "<style>" _n ///
        "body {font-family: Arial, sans-serif; margin: 20px; background: `bg_color'; color: `text_color';}" _n ///
        "h1 {text-align: center;}" _n ///
        "table {width: 95%; max-width: 1200px; margin: 20px auto; border-collapse: collapse;}" _n ///
        "th, td {border: 1px solid `border_color'; padding: 12px; text-align: left;}" _n ///
        "th {background: `header_bg'; font-weight: bold; text-align: center;}" _n ///
        "tr:nth-child(even) {background: `row_alt_bg';}" _n ///
        ".var-header {background: `header_bg'; font-weight: bold;}" _n ///
        ".continuous-stats {font-style: italic;}" _n ///
        ".number {text-align: center;}" _n ///
        ".center {text-align: center;}" _n ///
        "@media print {" _n ///
        "  body {background: white; color: black;}" _n ///
        "  table {border: 1px solid black;}" _n ///
        "  th, td {border: 1px solid black;}" _n ///
        "}" _n ///
        "@media (max-width: 600px) {" _n ///
        "  table {font-size: 14px;}" _n ///
        "  th, td {padding: 8px;}" _n ///
        "}" _n ///
        "</style></head><body>" _n ///
        "<h1>`title'</h1>" _n ///
        "<table>" _n ///
        "<tr><th>Đặc điểm</th><th class='number'>Tần số</th><th class='number'>Tỷ lệ (%)</th></tr>" _n

    foreach var of local varlist {
        cap {
            local vlab : variable label `var'
            if "`vlab'" == "" local vlab "`var'"

            qui codebook `var', compact
            local type = r(type)
            local N = r(N)

            local has_vallabel : value label `var'

            local is_continuous = 0
            if "`has_vallabel'" == "" {
                if r(unique) >= 10 {
                    qui sum `var'
                    if r(min) >= 0 & r(max) <= 100 & `N' > 0 {
                        local is_continuous = (r(unique) > 20)
                    }
                    else {
                        local is_continuous = 1
                    }
                }
            }

            file write html_output "<tr><td class='var-header'`indent_style'>`vlab'</td><td colspan='2'></td></tr>" _n

            if `is_continuous' {
                qui sum `var', detail
                local mean = string(r(mean), "%9.`digit'f")
                local sd = string(r(sd), "%9.`digit'f")
                local med = string(r(p50), "%9.`digit'f")
                local min = string(r(min), "%9.`digit'f")
                local max = string(r(max), "%9.`digit'f")
                local p25 = string(r(p25), "%9.`digit'f")
                local p75 = string(r(p75), "%9.`digit'f")

                file write html_output ///
                    "<tr><td class='continuous-stats'`indent_style'>Trung bình ± SD</td>" ///
                    "<td class='center' colspan='2'>`mean' ± `sd'</td></tr>" _n ///
                    "<tr><td class='continuous-stats'`indent_style'>Trung vị (IQR)</td>" ///
                    "<td class='center' colspan='2'>`med' (`p25' - `p75')</td></tr>" _n
            }
            else if strpos("`type'", "str") { // Biến chuỗi
                qui tab `var', missing
                local total_n = r(N)
                local missing = r(N_miss)

                quietly levelsof `var', local(all_values)
                foreach val of local all_values {
                    quietly count if `var' == `val'
                    local f = r(N)
                    local vl : label (`var') `val'
                    if "`vl'" == "" {
                        local vl "`val'"
                    }
                    local p = string(100 * `f'/`total_n', "%9.`digit'f")
                    file write html_output "<tr><td`indent_style'>`vl'</td><td class='number'>`f'</td><td class='number'>`p' %</td></tr>" _n
                }

                if `missing' > 0 { 
                    // Kiểm tra xem có giá trị missing nào được gán nhãn là "." hay không
                    local missing_label : label (`var') .
                    if "`missing_label'" != "" {
                        local missing_display "`missing_label'" 
                    }
                    else {
                        local missing_display "" // Hiển thị ô trống nếu không có nhãn "."
                    }

                    local mp = string(100 * `missing'/`total_n', "%9.`digit'f")
                    file write html_output "<tr><td`indent_style'>`missing_display'</td>" ///
                        "<td class='number'>`missing'</td><td class='number'>`mp' %</td></tr>" _n
                }
            }
            else { // Biến phân loại
                qui tab `var', missing
                local total_n = r(N)
                local missing = r(N_miss)

                if r(N_miss) == 0 { // Không có missing
                    qui tab `var', matcell(freq) matrow(values)
                }
                else { // Có missing, cần loại bỏ để sort chính xác
                    qui tab `var' if !missing(`var'), matcell(freq) matrow(values)
                }

                if "`nosort'" == "" {
                    mata: st_matrix("freq_sorted", sort((st_matrix("values"), st_matrix("freq")), -2))
                    matrix values = freq_sorted[1...,1]
                    matrix freq = freq_sorted[1...,2]
                }

                forvalues i = 1/`=rowsof(freq)' {
                    local val = values[`i',1]
                    local f = freq[`i',1]
                    local p = string(100 * `f'/`total_n', "%9.`digit'f")

                    if "`has_vallabel'" != "" {
                        local vl : label (`var') `val'
                        if "`vl'" != "" {
                            file write html_output "<tr><td`indent_style'>`vl'</td>" ///
                                "<td class='number'>`f'</td><td class='number'>`p' %</td></tr>" _n
                        }
                    }
                    else {
                        local vl = string(`val')
                        file write html_output "<tr><td`indent_style'>`vl'</td>" ///
                            "<td class='number'>`f'</td><td class='number'>`p' %</td></tr>" _n
                    }
                }

                if `missing' > 0 { 
                    // Kiểm tra xem có giá trị missing nào được gán nhãn là "." hay không
                    local missing_label : label (`var') .
                    if "`missing_label'" != "" {
                        local missing_display "`missing_label'" 
                    }
                    else {
                        local missing_display "" // Hiển thị ô trống nếu không có nhãn "."
                    }

                    local mp = string(100 * `missing'/`total_n', "%9.`digit'f")
                    file write html_output "<tr><td`indent_style'>`missing_display'</td>" ///
                        "<td class='number'>`missing'</td><td class='number'>`mp' %</td></tr>" _n
                }
            }
        }
        if _rc {
            display as error "Lỗi khi xử lý biến `var'"
            continue
        }
    }

    local timestamp = c(current_date) + " " + c(current_time)
    file write html_output "</table>" _n ///
        "<p><small>Được tạo lúc: `timestamp'</small></p>" _n ///
        "</body></html>" _n

    file close html_output

    local fullpath = "file://" + c(pwd) + "/" + "`output'"
    display as text _n "Đã lưu kết quả HTML. Nhấn vào đây để mở: {browse `fullpath'}"

    if "`autoopen'" != "" {
        shell start "`output'"
    }

    return local output "`output'"
    return local timestamp "`timestamp'"
end