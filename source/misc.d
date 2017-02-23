module misc;

import vibe.data.json;
import std.conv: to;

/// ditto
T getFromJson(T)(inout Json j, string fieldName, T defaultValue)
{
    auto json = j[fieldName];

    if(json.type == Json.Type.undefined)
        return defaultValue;
    else
        return json.to!T;
}
