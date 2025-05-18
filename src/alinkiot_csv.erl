-module(alinkiot_csv).
-export([
    export/2, 
    export/3, 
    export_by_config/3, 
    import/2,  
    import_by_config/2, 
    import_by_config/3,
    get_template/1
]).

-export([read_json_config/1]).

-include_lib("kernel/include/file.hrl").
-include_lib("stdlib/include/assert.hrl").

%% Export CSV function
%% Parameters:
%%   Name - filename (without extension)
%%   Data - list of maps with device data
export(Name, Data) ->
    Format = fun(_, Value) -> Value  end,
    export(Name, Data, Format).

export(Name, Data, Format) ->
    Config = read_json_config(Name),
    Bin = export_by_config(Config, Data, Format),
    {ok, Bin}.

export_by_config(Config, Data, Format) ->
    Fields = maps:get(<<"fields">>, Config),
    HeaderLines = [
        "字段说明,,,\n",
        "字段名称,字段标识,类型,说明\n",
        [format_field_description(Field) || Field <- Fields],
        ",,,\n",
        [format_field_header(Field) || Field <- Fields],
        "\n"
    ],
    DataLines = [
        [format_data_row(Row, Fields, Format) || Row <- Data]
    ],
    unicode:characters_to_binary([HeaderLines, DataLines]).

format_field_description(#{<<"title">> := Title, <<"name">> := Name,
    <<"type">> := Type, <<"description">> := Desc}) ->
    [unicode:characters_to_list(Title), ",", unicode:characters_to_list(Name), ",",
        unicode:characters_to_list(Type), ",", unicode:characters_to_list(Desc), "\n"].

format_field_header(#{<<"title">> := Title}) ->
    unicode:characters_to_list(Title) ++ ",".

format_data_row(Row, Fields, Format) ->
    [case maps:get(<<"name">>, Field, undefined) of
         undefined -> "";
         FieldName ->
             Value = maps:get(FieldName, Row, ""),
             to_string(Format(FieldName, Value))
     end ++ "," || Field <- Fields] ++ "\n".

%% Import CSV function
%% Parameters:
%%   Name - filename (without extension)
%%   FilePath - path to CSV file
%% Returns: list of maps with imported data
import(Name, FilePath) ->
    Config = read_json_config(Name),
    import_by_config(Config, FilePath).

%% 产生导入模板 csv
get_template(Name) ->
    Config = read_json_config(Name),
    Fields = maps:get(<<"fields">>, Config),
    HeaderLines = [
        [format_field_header(Field) || Field <- Fields],
        "\n"
    ],
    {ok, unicode:characters_to_binary([HeaderLines])}.    

import_by_config(Config, FilePath) ->
    Format = fun(_, Value) -> Value  end,
    import_by_config(Config, FilePath, Format).

import_by_config(Config, FilePath, Format) ->
    Fields = maps:get(<<"fields">>, Config),
    {ok, File} = file:open(FilePath, [read]),
    FieldNames = read_data_header(File, Fields),
    Data = read_data_lines(File, FieldNames, Format),
    file:close(File),
    Data.

read_data_header(File, Fields) ->
    case io:get_line(File, '') of
        eof -> [];
        "\n" -> [];
        Line ->
            Titles = binary:split(iolist_to_binary(Line), <<",">>, [global]),
            lists:foldr(fun(Title, Acc) ->
                get_field_name(Title, Fields, Acc)
            end, [], Titles)
    end.

get_field_name(<<"\n">>, _Fields, Acc) -> Acc;
get_field_name(<<>>, _Fields, Acc) -> Acc;
get_field_name(_Title, [], Acc) -> Acc;
get_field_name(Title, [#{<<"title">> := Title } = Field | _], Acc) ->
    [Field | Acc];
get_field_name(Title, [_ | Rest], Acc) ->
    get_field_name(Title, Rest, Acc).

read_data_lines(File, FieldNames, Format) ->
    case io:get_line(File, '') of
        eof -> [];
        "\n" -> [];
        Line ->
            Values = binary:split(iolist_to_binary(Line), <<",">>, [global]),
            Row = lists_zip(FieldNames, Values, Format),
            [maps:from_list(Row) | read_data_lines(File, FieldNames, Format)]
    end.

lists_zip(_, [], _Format) -> [];
lists_zip([], _, _) -> [];
lists_zip([#{ <<"name">> := Name, <<"type">> := Type } | Fields], [Value | Values], Format) ->
    [{Name, Format(Name, format_value(Type, Value))} | lists_zip(Fields, Values, Format)].


format_value(<<"int">>, Value) ->
    binary_to_integer(Value);
format_value(<<"float">>, Value) ->
    binary_to_float(Value);
format_value(<<"string">>, Value) ->
    Value.

%% Read JSON configuration from priv directory
read_json_config(Name) ->
    Dir = code:priv_dir(alinkiot_csv),
    FilePath = filename:join([Dir, Name ++ ".json"]),
    {ok, Bin} = file:read_file(FilePath),
    jiffy:decode(Bin, [return_maps]).

%% Helper function to convert various types to string
to_string(Value) when is_binary(Value) -> binary_to_list(Value);
to_string(Value) when is_atom(Value) -> atom_to_list(Value);
to_string(Value) when is_integer(Value) -> integer_to_list(Value);
to_string(Value) when is_float(Value) -> float_to_list(Value);
to_string(Value) when is_list(Value) -> Value.
