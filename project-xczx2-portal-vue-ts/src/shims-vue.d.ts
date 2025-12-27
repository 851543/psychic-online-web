declare module '*.vue' {
  import Vue from 'vue'
  export default Vue
}

declare module '*.png' {
  const src: string
  export default src
}
