#let trang_phu_bia(title, authors, instructors) = {
  rect(
    stroke: 5pt,
    inset: 7pt,
  rect(
    width: 100%,
    height: 100%,
    inset: 15pt,
    stroke: 1.7pt,
    [
      #align(center)[
      #text(12pt, strong("ĐẠI HỌC QUỐC GIA HÀ NỘI"))
  
      #text(12pt, strong("TRƯỜNG ĐẠI HỌC CÔNG NGHỆ"))
      ]
      #v(1.5cm)

      
      #align(center)[
        #text(14pt, strong("NHÓM 1"))
      ]
      
      #v(2cm)
      #align(center)[
        #set par(
          justify: false,
        )
        #text(18pt,  upper(strong(title)))
      ]
      #v(2cm)
      #align(center)[
        #text(14pt, strong("BÁO CÁO BÀI TẬP LỚN"))
      ]
      #align(center)[
        #text(14pt, strong("Môn học: INT3310 1 - Quản trị mạng"))
      ]
      #v(1.5cm)
      #align(center)[
        #grid(
          columns: 2,
          align: (x, _) => if x == 0 { end } else { start },
          column-gutter: 2em,
          row-gutter: 2em,
          [#text(13pt, "Giảng viên hướng dẫn:   ")], [
              #instructors.map(instructor => 
              text(13pt, strong(instructor.name))
            ).join([#v(0.1pt)])
          ],
          [#text(13pt, "Sinh viên thực hiện:   ")], [
              #authors.map(author => 
              text(13pt, strong(author.name))
            ).join([#v(0.1pt)])
          ],
        )
      ]
      #v(1fr)
    
      #align(center)[
        #text(12pt, strong("HÀ NỘI - 2025"))
      ]
    ]  
  ))
}
