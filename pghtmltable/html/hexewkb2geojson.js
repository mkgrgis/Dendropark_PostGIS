function hexToBytes(hex) {
  if (hex.startsWith("\\x")) hex = hex.slice(2);
  const bytes = new Uint8Array(hex.length / 2);
  for (let i = 0; i < bytes.length; i++) {
    bytes[i] = parseInt(hex.substr(i * 2, 2), 16);
  }
  return bytes;
}

function readUInt32(view, offset, littleEndian) {
  return view.getUint32(offset, littleEndian);
}

function readDouble(view, offset, littleEndian) {
  return view.getFloat64(offset, littleEndian);
}

function parseWKB(bytes) {
  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  let o = 0;

  function parseGeom() {
    const little = view.getUint8(o++) === 1;
    let type = readUInt32(view, o, little);
    o += 4;

    const hasZ = !!(type & 0x80000000);
    const hasM = !!(type & 0x40000000);
    const hasSRID = !!(type & 0x20000000);
    type = type & 0x000000ff;

    if (hasSRID) o += 4;

    const dim = 2 + (hasZ ? 1 : 0) + (hasM ? 1 : 0);

    const readPoint = () => {
      const coords = [];
      for (let i = 0; i < dim; i++) {
        coords.push(readDouble(view, o, little));
        o += 8;
      }
      return coords;
    };

    if (type === 1) return { type: "Point", coordinates: readPoint() };

    if (type === 2) {
      const n = readUInt32(view, o, little); o += 4;
      const coords = [];
      for (let i = 0; i < n; i++) coords.push(readPoint());
      return { type: "LineString", coordinates: coords };
    }

    if (type === 3) {
      const n = readUInt32(view, o, little); o += 4;
      const rings = [];
      for (let r = 0; r < n; r++) {
        const m = readUInt32(view, o, little); o += 4;
        const ring = [];
        for (let i = 0; i < m; i++) ring.push(readPoint());
        rings.push(ring);
      }
      return { type: "Polygon", coordinates: rings };
    }

    if (type === 4) {
      const n = readUInt32(view, o, little); o += 4;
      const geoms = [];
      for (let i = 0; i < n; i++) geoms.push(parseGeom());
      return { type: "MultiPoint", coordinates: geoms.map(g => g.coordinates) };
    }

    if (type === 5) {
      const n = readUInt32(view, o, little); o += 4;
      const geoms = [];
      for (let i = 0; i < n; i++) geoms.push(parseGeom());
      return { type: "MultiLineString", coordinates: geoms.map(g => g.coordinates) };
    }

    if (type === 6) {
      const n = readUInt32(view, o, little); o += 4;
      const geoms = [];
      for (let i = 0; i < n; i++) geoms.push(parseGeom());
      return { type: "MultiPolygon", coordinates: geoms.map(g => g.coordinates) };
    }

    if (type === 7) {
      const n = readUInt32(view, o, little); o += 4;
      const geoms = [];
      for (let i = 0; i < n; i++) geoms.push(parseGeom());
      return { type: "GeometryCollection", geometries: geoms };
    }

    throw new Error("Unsupported WKB type: " + type);
  }

  return parseGeom();
}

function hexEwkbToGeoJSON(hex) {
  const bytes = hexToBytes(hex);
  const geom = parseWKB(bytes);
  return geom.type === "GeometryCollection"
    ? { type: "GeometryCollection", geometries: geom.geometries }
    : { type: "Feature", properties: {}, geometry: geom };
}

const world = [[180, -90], [180, 90], [-180, 90], [-180, -90]];
