process square {
    input:
    val x

    output:
    stdout

    script:
    """
    echo \$(( ${x} * ${x} ))
    """
}

workflow {
    Channel.of(1, 2, 3, 4) | square | map { it.trim() as int } | collect | map { it.sum() } | view { "sum of squares = $it" }
}
