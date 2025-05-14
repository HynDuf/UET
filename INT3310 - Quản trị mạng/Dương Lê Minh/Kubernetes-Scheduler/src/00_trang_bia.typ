#let trang_bia(title, authors) = {
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
      #v(0.6cm)
      #align(center)[
        #image("/images/UET.png", width: 25%)
      ]
      #v(0.7cm)
      
      #align(center)[
        #text(14pt, strong("Nhóm 1"))
      ]
      
      #v(1.2cm)
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

      #v(1fr)
    
      #align(center)[
        #text(12pt, strong("HÀ NỘI - 2025"))
      ]
    ]  
  ))
}
