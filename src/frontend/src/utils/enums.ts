function enumValues<EV extends (string|number), ET extends { [key: string]: EV }>(e: ET) {
  const values:EV[] = Object.values(e)
  const isNumEnum = e[e[values[0]]] === values[0]
  return isNumEnum ? values.slice(values.length / 2) : values
}

export { enumValues }