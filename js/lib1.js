/* DO NOT EDIT: This file is automatically generated by Cabal */

/* package base-4.7.0.1 */






/* package bytestring-0.10.4.1 */






/* package either-4.3.2 */






/* package ghcjs-base-0.1.0.0 */






/* package ghcjs-ffiqq-0.1.0.0 */






/* package ghcjs-prim-0.1.0.0 */






/* package hashable-1.2.2.0 */






/* package lens-4.5 */






/* package mtl-2.2.1 */






/* package pretty-show-1.6.8 */






/* package text-1.1.1.3 */






/* package time-1.4.2 */






/* package transformers-0.4.1.0 */






/* package unordered-containers-0.2.5.0 */






/* tool alex-3.1.3 */






/* tool cpphs-1.18.5 */






/* tool gcc-4.2.1 */






/* tool ghc-7.8.3 */






/* tool ghc-pkg-7.8.3 */






/* tool ghcjs-0.1.0 */






/* tool ghcjs-pkg-0.1.0 */






/* tool haddock-2.14.3 */






/* tool happy-1.19.4 */






/* tool hpc-0.67 */






/* tool hsc2hs-0.67 */






/* tool hscolour-1.20 */






/* tool pkg-config-0.28 */
// some Enum conversion things

// an array of generic enums
var h$enums = [];
function h$initEnums() {
  for(var i=0;i<256;i++) {
    h$enums[i] = h$makeEnum(i);
  }
}
h$initStatic.push(h$initEnums);

function h$makeEnum(tag) {
  var f = function() {
    return h$stack[h$sp];
  }
  h$setObjInfo(f, 2, "Enum", [], tag+1, 0, [1], null);



  return h$c0(f);

}

// used for all non-Bool enums
function h$tagToEnum(tag) {
  if(tag >= h$enums.length) {
    return h$makeEnum(tag);
  } else {
    return h$enums[tag];
  }
}

function h$dataTag(e) {
  return (e===true)?1:((typeof e !== 'object')?0:(e.f.a-1));
}
