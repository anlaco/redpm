Red [
    Title: utils
]

delete-dir: func [path [file!]][
    if not dir? path [path: append path #"/"]
    foreach file read path [
        either dir? path/:file [
            delete-dir path/:file    ;Si es carpeta, recursión
        ][
            delete path/:file        ;Si es archivo, borrar
        ]
    ]
    delete path  ;Finalmente borra la carpeta vacia
]