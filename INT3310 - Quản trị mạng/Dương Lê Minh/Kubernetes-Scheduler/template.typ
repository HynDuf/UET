#import "@preview/showybox:2.0.1" : showybox
#import "src/00_trang_bia.typ": trang_bia
#import "src/01_trang_phu_bia.typ": trang_phu_bia
#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.8": *

#let outline_algo(x, caption, label) = {
  return [
    #figure(x, kind: "algo", supplement: [Thuật toán], caption: caption) #label
  ]
}
#let heading_numbering(..nums) = {
  return str(counter(heading).get().first()) + "." + nums
  .pos()
  .map(str)
  .join(".")
}

#let phuluc_numbering(..nums) = {
  return str.from-unicode(counter(heading).get().at(1) + 64) + "." + nums
  .pos()
  .map(str)
  .join(".")
}

#let numbered_equation(content, label) = {
  return [
    #set math.equation(
      numbering: (..nums) => "(" + str(counter(heading).get().first()) + "." + nums.pos().map(str).join(".") + ")",
    )
    #content
    #label
  ]
}
#let output_box(content) = {
  showybox(
    breakable: true,
    frame: (border-color: gray, title-color: gray.lighten(80%), radius: 0pt),
    title-style: (color: black, boxed-style: (anchor: (x: left, y: horizon), radius: 0pt)),
    title: "Output",
    content,
  )
}
// Project part
#let project(title: "", authors: (), instructors: (), body) = {
  // Set the document's basic properties.
  set document(author: authors.map(a => a.name), title: title)
  set page(paper: "a4", margin: (top: 2.5cm, bottom: 2.5cm, left: 2cm, right: 2cm))
  // set text(font: "SVN-Times New Roman", lang: "vi", size: 13pt)
  set text(font: "New Computer Modern", lang: "vi", size: 13pt)
  set par(justify: true)
  // ================= Trang Bia =====================
  trang_bia(title, authors)
  trang_phu_bia(title, authors, instructors)
  // =================================================

  counter(page).update(0)
  set page(numbering: "i")
  include "src/03_loi_cam_doan.typ"
  include "src/02_tom_tat.typ"

  show heading.where(level: 1): it => [
    #counter(figure.where(kind: image)).update(0)
    #counter(figure.where(kind: table)).update(0)
    #pagebreak(weak: true)
    #if (not str(counter(heading).display()).starts-with("Chương")) {
      text(35pt, it)
    } else {
      block([
        #set par(first-line-indent: 0pt)
        #text(35pt, counter(heading).display())

        #text(35pt, it.body)

        #v(1cm)
      ])
    }
  ]

  // ================= Muc Luc =====================
  {
    show outline.entry.where(level: 1): it => {
      v(20pt, weak: true)
      strong(
        {
          if (it.element.numbering != none) {
            let number = numbering(it.element.numbering, ..counter(heading).at(it.element.location()))
            box(width: 5em, number) + ". "
          }
          link(it.element.location())[#it.element.body ]
          box(width: 1fr, it.fill)
          h(3pt)
          link(it.element.location())[#it.page()]
        },
      )
    }
    show outline.entry.where(level: 2): it => {
      v(20pt, weak: true)
      h(1.5em)
      if (it.element.numbering != none) {
        let number = numbering(it.element.numbering, ..counter(heading).at(it.element.location()))
        box(width: 1.7em, number)
      }
      link(it.element.location())[ #it.element.body ]
      box(width: 1fr, it.fill)
      h(3pt)
      link(it.element.location())[#it.page()]
    }
    show outline.entry.where(level: 3): it => {
      v(20pt, weak: true)
      h(3.6em)
      if (it.element.numbering != none) {
        let number = numbering(it.element.numbering, ..counter(heading).at(it.element.location()))
        box(width: 2.4em, number)
      }
      link(it.element.location())[ #it.element.body ]
      box(width: 1fr, it.fill)
      h(3pt)
      link(it.element.location())[#it.page()]
    }
    // show outline.entry.where(
    //   level: 3
    // ): it => {
    //   v(20pt, weak: true)
    //   pad(left: 5.6em, top: -5pt, bottom: -25pt, [
    //     #h(-2.7em)
    //     #if (it.element.numbering != none) {
    //       let number = numbering(it.element.numbering, ..counter(heading).at(it.element.location()))
    //       box(width: 2.3em, number)
    //     }
    //     #link(it.element.location())[ #it.element.body]
    //     #h(3pt)
    //     #box(width: 1fr, it.fill)
    //     #h(3pt)
    //     #link(it.element.location())[#it.page]
    //   ])
    // }
    {
      show heading: none
      heading(numbering: none)[Mục lục]
    }
    align(center, text(16pt, [*MỤC LỤC*]))
    v(7pt)
    outline(title: none, depth: 3)
    pagebreak()
  }
  {
    // citation dup in caption
    // https://github.com/typst/typst/issues/1880
    set footnote.entry(separator: none)
    show footnote.entry: hide
    show ref: none
    show footnote: none

    {
      show heading: none
      heading(numbering: none)[Danh mục hình ảnh]
    }
    align(center, text(16pt, [*DANH MỤC HÌNH ẢNH*]))
    v(7pt)
    outline(title: none, target: figure.where(kind: image))
    pagebreak()

  }

  // ===============================================

  // set page(header: [
  //   #set text(luma(130), size: 12pt)

  //   #context {
  //     // Find if there is a level 1 heading on the current page
  //     let nextMainHeading = query(selector(heading).after(here())).find(headIt => {
  //      headIt.location().page() == here().page() and headIt.level == 1
  //     })
  //     if (nextMainHeading == none) {
  //       let page_number = context counter(page).display(
  //         "1 ",
  //       )
  //       if calc.even(here().page()) {
  //         "Trang "
  //         page_number
  //         box(width: 1fr, line(length: 100%, stroke: 0.4pt + luma(120)))
  //       } else {
  //         box(width: 1fr, line(length: 100%, stroke: 0.4pt + luma(120)))
  //         " Trang "
  //         page_number
  //       }
  //     }
  //   }
  // ])

  // set page(footer: context [
  //   #set text(luma(130), size: 12pt)
  //   _Huỳnh Nguyễn Phương Trang - Giáo dục Toán học K32 _
  //   #box(width: 1fr, line(length: 100%, stroke: (paint: luma(120), dash: "loosely-dotted")))
  //   Trang
  //   #counter(page).display(
  //     "1",
  //   )
  // ])

  // show heading: set text(13pt)

  set par(leading: 0.8em, spacing: 1.5em)
  set block(spacing: 1.2em)
  set list(indent: 0.8em)
  show heading: set block(spacing: 1.5em)
  show link: set text(fill: rgb("#0028d9"))
  show ref: it => {
    if it.element == none {
      return it
    }
    set text(fill: rgb("#0028d9"))
    it
  }

  show cite: it => {
    show regex("\d+"): set text(rgb("#0028d9"))
    it
  }
  set figure.caption(separator: [ --- ])
  set figure(gap: 3pt, numbering: heading_numbering)

  show figure.where(kind: image): set figure(gap: 15pt, numbering: heading_numbering)
  show figure.caption: c => [
    #context text(weight: "bold")[
    #c.supplement #c.counter.display(c.numbering)
    ]
    #c.separator#c.body
    #v(0.4cm)
  ]
  show figure.where(kind: table): set figure.caption(position: top)
  show figure.where(kind: "algo"): set figure.caption(position: top)

  show raw.where(block: false): box.with(
    fill:  luma(240), 
    stroke: rgb(239, 240, 243),
    inset: (x: 3pt, y: 1pt),
    outset: (y: 3pt),
    radius: 3pt,
  )
  show raw: set text(font: "Source Code Pro")
  show: codly-init.with()
  codly(languages: codly-languages, number-format: none, lang-outset: (x: -2pt, y: 0pt))

  // ============ MATH ==============
  set math.cases(gap: 1.2em)
  set math.equation(supplement: none)

  body
}

#let dfrac(x, y) = math.equation(block(inset: (top: 0.5em, bottom: 0.8em))[#text(size: 18pt)[#math.frac(x, y)]])

