// line 1 "parser.java.rl"
/**
 * Copyright (c) 2005 Zed A. Shaw
 * You can redistribute it and/or modify it under the same terms as Ruby.
 */
package org.thin;

import org.jruby.util.ByteList;

public class HttpParser {

/** Machine **/

// line 69 "parser.java.rl"


/** Data **/

// line 20 "org/thin/HttpParser.java"
private static byte[] init__http_parser_actions_0()
{
	return new byte [] {
	    0,    1,    0,    1,    1,    1,    2,    1,    3,    1,    4,    1,
	    5,    1,    6,    1,    7,    1,    8,    1,   10,    1,   11,    1,
	   12,    2,    0,    7,    2,    3,    4,    2,    9,    6,    2,   11,
	    6,    3,    8,    9,    6
	};
}

private static final byte _http_parser_actions[] = init__http_parser_actions_0();


private static short[] init__http_parser_key_offsets_0()
{
	return new short [] {
	    0,    0,    8,   17,   27,   29,   30,   31,   32,   33,   34,   36,
	   39,   41,   44,   45,   61,   62,   78,   80,   81,   87,   93,   99,
	  105,  115,  121,  127,  133,  141,  147,  153,  160,  166,  172,  178,
	  184,  190,  196,  205,  214,  223,  232,  241,  250,  259,  268,  277,
	  286,  295,  304,  313,  322,  331,  340,  349,  358,  359
	};
}

private static final short _http_parser_key_offsets[] = init__http_parser_key_offsets_0();


private static char[] init__http_parser_trans_keys_0()
{
	return new char [] {
	   36,   95,   45,   46,   48,   57,   65,   90,   32,   36,   95,   45,
	   46,   48,   57,   65,   90,   42,   43,   47,   58,   45,   57,   65,
	   90,   97,  122,   32,   35,   72,   84,   84,   80,   47,   48,   57,
	   46,   48,   57,   48,   57,   13,   48,   57,   10,   13,   33,  124,
	  126,   35,   39,   42,   43,   45,   46,   48,   57,   65,   90,   94,
	  122,   10,   33,   58,  124,  126,   35,   39,   42,   43,   45,   46,
	   48,   57,   65,   90,   94,  122,   13,   32,   13,   32,   35,   37,
	  127,    0,   31,   32,   35,   37,  127,    0,   31,   48,   57,   65,
	   70,   97,  102,   48,   57,   65,   70,   97,  102,   43,   58,   45,
	   46,   48,   57,   65,   90,   97,  122,   32,   35,   37,  127,    0,
	   31,   48,   57,   65,   70,   97,  102,   48,   57,   65,   70,   97,
	  102,   32,   35,   37,   59,   63,  127,    0,   31,   48,   57,   65,
	   70,   97,  102,   48,   57,   65,   70,   97,  102,   32,   35,   37,
	   63,  127,    0,   31,   48,   57,   65,   70,   97,  102,   48,   57,
	   65,   70,   97,  102,   32,   35,   37,  127,    0,   31,   32,   35,
	   37,  127,    0,   31,   48,   57,   65,   70,   97,  102,   48,   57,
	   65,   70,   97,  102,   32,   36,   95,   45,   46,   48,   57,   65,
	   90,   32,   36,   95,   45,   46,   48,   57,   65,   90,   32,   36,
	   95,   45,   46,   48,   57,   65,   90,   32,   36,   95,   45,   46,
	   48,   57,   65,   90,   32,   36,   95,   45,   46,   48,   57,   65,
	   90,   32,   36,   95,   45,   46,   48,   57,   65,   90,   32,   36,
	   95,   45,   46,   48,   57,   65,   90,   32,   36,   95,   45,   46,
	   48,   57,   65,   90,   32,   36,   95,   45,   46,   48,   57,   65,
	   90,   32,   36,   95,   45,   46,   48,   57,   65,   90,   32,   36,
	   95,   45,   46,   48,   57,   65,   90,   32,   36,   95,   45,   46,
	   48,   57,   65,   90,   32,   36,   95,   45,   46,   48,   57,   65,
	   90,   32,   36,   95,   45,   46,   48,   57,   65,   90,   32,   36,
	   95,   45,   46,   48,   57,   65,   90,   32,   36,   95,   45,   46,
	   48,   57,   65,   90,   32,   36,   95,   45,   46,   48,   57,   65,
	   90,   32,   36,   95,   45,   46,   48,   57,   65,   90,   32,    0
	};
}

private static final char _http_parser_trans_keys[] = init__http_parser_trans_keys_0();


private static byte[] init__http_parser_single_lengths_0()
{
	return new byte [] {
	    0,    2,    3,    4,    2,    1,    1,    1,    1,    1,    0,    1,
	    0,    1,    1,    4,    1,    4,    2,    1,    4,    4,    0,    0,
	    2,    4,    0,    0,    6,    0,    0,    5,    0,    0,    4,    4,
	    0,    0,    3,    3,    3,    3,    3,    3,    3,    3,    3,    3,
	    3,    3,    3,    3,    3,    3,    3,    3,    1,    0
	};
}

private static final byte _http_parser_single_lengths[] = init__http_parser_single_lengths_0();


private static byte[] init__http_parser_range_lengths_0()
{
	return new byte [] {
	    0,    3,    3,    3,    0,    0,    0,    0,    0,    0,    1,    1,
	    1,    1,    0,    6,    0,    6,    0,    0,    1,    1,    3,    3,
	    4,    1,    3,    3,    1,    3,    3,    1,    3,    3,    1,    1,
	    3,    3,    3,    3,    3,    3,    3,    3,    3,    3,    3,    3,
	    3,    3,    3,    3,    3,    3,    3,    3,    0,    0
	};
}

private static final byte _http_parser_range_lengths[] = init__http_parser_range_lengths_0();


private static short[] init__http_parser_index_offsets_0()
{
	return new short [] {
	    0,    0,    6,   13,   21,   24,   26,   28,   30,   32,   34,   36,
	   39,   41,   44,   46,   57,   59,   70,   73,   75,   81,   87,   91,
	   95,  102,  108,  112,  116,  124,  128,  132,  139,  143,  147,  153,
	  159,  163,  167,  174,  181,  188,  195,  202,  209,  216,  223,  230,
	  237,  244,  251,  258,  265,  272,  279,  286,  293,  295
	};
}

private static final short _http_parser_index_offsets[] = init__http_parser_index_offsets_0();


private static byte[] init__http_parser_indicies_0()
{
	return new byte [] {
	    0,    0,    0,    0,    0,    1,    2,    3,    3,    3,    3,    3,
	    1,    4,    5,    6,    7,    5,    5,    5,    1,    8,    9,    1,
	   10,    1,   11,    1,   12,    1,   13,    1,   14,    1,   15,    1,
	   16,   15,    1,   17,    1,   18,   17,    1,   19,    1,   20,   21,
	   21,   21,   21,   21,   21,   21,   21,   21,    1,   22,    1,   23,
	   24,   23,   23,   23,   23,   23,   23,   23,   23,    1,   26,   27,
	   25,   29,   28,   30,    1,   32,    1,    1,   31,   33,    1,   35,
	    1,    1,   34,   36,   36,   36,    1,   34,   34,   34,    1,   37,
	   38,   37,   37,   37,   37,    1,    8,    9,   39,    1,    1,   38,
	   40,   40,   40,    1,   38,   38,   38,    1,   41,   43,   44,   45,
	   46,    1,    1,   42,   47,   47,   47,    1,   42,   42,   42,    1,
	    8,    9,   49,   50,    1,    1,   48,   51,   51,   51,    1,   48,
	   48,   48,    1,   52,   54,   55,    1,    1,   53,   56,   58,   59,
	    1,    1,   57,   60,   60,   60,    1,   57,   57,   57,    1,    2,
	   61,   61,   61,   61,   61,    1,    2,   62,   62,   62,   62,   62,
	    1,    2,   63,   63,   63,   63,   63,    1,    2,   64,   64,   64,
	   64,   64,    1,    2,   65,   65,   65,   65,   65,    1,    2,   66,
	   66,   66,   66,   66,    1,    2,   67,   67,   67,   67,   67,    1,
	    2,   68,   68,   68,   68,   68,    1,    2,   69,   69,   69,   69,
	   69,    1,    2,   70,   70,   70,   70,   70,    1,    2,   71,   71,
	   71,   71,   71,    1,    2,   72,   72,   72,   72,   72,    1,    2,
	   73,   73,   73,   73,   73,    1,    2,   74,   74,   74,   74,   74,
	    1,    2,   75,   75,   75,   75,   75,    1,    2,   76,   76,   76,
	   76,   76,    1,    2,   77,   77,   77,   77,   77,    1,    2,   78,
	   78,   78,   78,   78,    1,    2,    1,    1,    0
	};
}

private static final byte _http_parser_indicies[] = init__http_parser_indicies_0();


private static byte[] init__http_parser_trans_targs_0()
{
	return new byte [] {
	    2,    0,    3,   38,    4,   24,   28,   25,    5,   20,    6,    7,
	    8,    9,   10,   11,   12,   13,   14,   15,   16,   17,   57,   17,
	   18,   19,   14,   18,   19,   14,    5,   21,   22,    5,   21,   22,
	   23,   24,   25,   26,   27,    5,   28,   20,   29,   31,   34,   30,
	   31,   32,   34,   33,    5,   35,   20,   36,    5,   35,   20,   36,
	   37,   39,   40,   41,   42,   43,   44,   45,   46,   47,   48,   49,
	   50,   51,   52,   53,   54,   55,   56
	};
}

private static final byte _http_parser_trans_targs[] = init__http_parser_trans_targs_0();


private static byte[] init__http_parser_trans_actions_0()
{
	return new byte [] {
	    1,    0,   11,    0,    1,    1,    1,    1,   13,   13,    1,    0,
	    0,    0,    0,    0,    0,    0,   19,    0,    0,    3,   23,    0,
	    5,    7,   28,    7,    0,    9,   25,    1,    1,   15,    0,    0,
	    0,    0,    0,    0,    0,   34,    0,   34,    0,   21,   21,    0,
	    0,    0,    0,    0,   37,   17,   37,   17,   31,    0,   31,    0,
	    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
	    0,    0,    0,    0,    0,    0,    0
	};
}

private static final byte _http_parser_trans_actions[] = init__http_parser_trans_actions_0();


static final int http_parser_start = 1;
static final int http_parser_first_final = 57;
static final int http_parser_error = 0;

static final int http_parser_en_main = 1;

// line 73 "parser.java.rl"

   public static interface ElementCB {
     public void call(Object data, int at, int length);
   }

   public static interface FieldCB {
     public void call(Object data, int field, int flen, int value, int vlen);
   }

   public static class HttpParserMachine {
      int cs;
      int body_start;
      int content_len;
      int nread;
      int mark;
      int field_start;
      int field_len;
      int query_start;

      Object data;
      ByteList buffer;

      public FieldCB http_field;
      public ElementCB request_method;
      public ElementCB request_uri;
      public ElementCB fragment;
      public ElementCB request_path;
      public ElementCB query_string;
      public ElementCB http_version;
      public ElementCB header_done;

      public void init() {
          cs = 0;

          
// line 237 "org/thin/HttpParser.java"
	{
	cs = http_parser_start;
	}
// line 108 "parser.java.rl"

          body_start = 0;
          content_len = 0;
          mark = 0;
          nread = 0;
          field_len = 0;
          field_start = 0;
      }
   }

   public final HttpParserMachine parser = new HttpParserMachine();

   public int execute(ByteList buffer, int off) {
     int p, pe;
     int cs = parser.cs;
     int len = buffer.realSize;
     assert off<=len : "offset past end of buffer";

     p = off;
     pe = len;
     byte[] data = buffer.bytes;
     parser.buffer = buffer;

     
// line 266 "org/thin/HttpParser.java"
	{
	int _klen;
	int _trans = 0;
	int _acts;
	int _nacts;
	int _keys;
	int _goto_targ = 0;

	_goto: while (true) {
	switch ( _goto_targ ) {
	case 0:
	if ( p == pe ) {
		_goto_targ = 4;
		continue _goto;
	}
	if ( cs == 0 ) {
		_goto_targ = 5;
		continue _goto;
	}
case 1:
	_match: do {
	_keys = _http_parser_key_offsets[cs];
	_trans = _http_parser_index_offsets[cs];
	_klen = _http_parser_single_lengths[cs];
	if ( _klen > 0 ) {
		int _lower = _keys;
		int _mid;
		int _upper = _keys + _klen - 1;
		while (true) {
			if ( _upper < _lower )
				break;

			_mid = _lower + ((_upper-_lower) >> 1);
			if ( data[p] < _http_parser_trans_keys[_mid] )
				_upper = _mid - 1;
			else if ( data[p] > _http_parser_trans_keys[_mid] )
				_lower = _mid + 1;
			else {
				_trans += (_mid - _keys);
				break _match;
			}
		}
		_keys += _klen;
		_trans += _klen;
	}

	_klen = _http_parser_range_lengths[cs];
	if ( _klen > 0 ) {
		int _lower = _keys;
		int _mid;
		int _upper = _keys + (_klen<<1) - 2;
		while (true) {
			if ( _upper < _lower )
				break;

			_mid = _lower + (((_upper-_lower) >> 1) & ~1);
			if ( data[p] < _http_parser_trans_keys[_mid] )
				_upper = _mid - 2;
			else if ( data[p] > _http_parser_trans_keys[_mid+1] )
				_lower = _mid + 2;
			else {
				_trans += ((_mid - _keys)>>1);
				break _match;
			}
		}
		_trans += _klen;
	}
	} while (false);

	_trans = _http_parser_indicies[_trans];
	cs = _http_parser_trans_targs[_trans];

	if ( _http_parser_trans_actions[_trans] != 0 ) {
		_acts = _http_parser_trans_actions[_trans];
		_nacts = (int) _http_parser_actions[_acts++];
		while ( _nacts-- > 0 )
	{
			switch ( _http_parser_actions[_acts++] )
			{
	case 0:
// line 17 "parser.java.rl"
	{parser.mark = p; }
	break;
	case 1:
// line 19 "parser.java.rl"
	{ parser.field_start = p; }
	break;
	case 2:
// line 21 "parser.java.rl"
	{ 
    parser.field_len = p-parser.field_start;
  }
	break;
	case 3:
// line 25 "parser.java.rl"
	{ parser.mark = p; }
	break;
	case 4:
// line 26 "parser.java.rl"
	{ 
    if(parser.http_field != null) {
      parser.http_field.call(parser.data, parser.field_start, parser.field_len, parser.mark, p-parser.mark);
    }
  }
	break;
	case 5:
// line 31 "parser.java.rl"
	{ 
    if(parser.request_method != null) 
      parser.request_method.call(parser.data, parser.mark, p-parser.mark);
  }
	break;
	case 6:
// line 35 "parser.java.rl"
	{ 
    if(parser.request_uri != null)
      parser.request_uri.call(parser.data, parser.mark, p-parser.mark);
  }
	break;
	case 7:
// line 39 "parser.java.rl"
	{ 
    if(parser.fragment != null)
      parser.fragment.call(parser.data, parser.mark, p-parser.mark);
  }
	break;
	case 8:
// line 44 "parser.java.rl"
	{parser.query_start = p; }
	break;
	case 9:
// line 45 "parser.java.rl"
	{ 
    if(parser.query_string != null)
      parser.query_string.call(parser.data, parser.query_start, p-parser.query_start);
  }
	break;
	case 10:
// line 50 "parser.java.rl"
	{	
    if(parser.http_version != null)
      parser.http_version.call(parser.data, parser.mark, p-parser.mark);
  }
	break;
	case 11:
// line 55 "parser.java.rl"
	{
    if(parser.request_path != null)
      parser.request_path.call(parser.data, parser.mark, p-parser.mark);
  }
	break;
	case 12:
// line 60 "parser.java.rl"
	{ 
    parser.body_start = p + 1; 
    if(parser.header_done != null)
      parser.header_done.call(parser.data, p + 1, pe - p - 1);
    { p += 1; _goto_targ = 5; if (true)  continue _goto;}
  }
	break;
// line 427 "org/thin/HttpParser.java"
			}
		}
	}

case 2:
	if ( cs == 0 ) {
		_goto_targ = 5;
		continue _goto;
	}
	if ( ++p != pe ) {
		_goto_targ = 1;
		continue _goto;
	}
case 4:
case 5:
	}
	break; }
	}
// line 132 "parser.java.rl"

     parser.cs = cs;
     parser.nread += (p - off);
     
     assert p <= pe                  : "buffer overflow after parsing execute";
     assert parser.nread <= len      : "nread longer than length";
     assert parser.body_start <= len : "body starts after buffer end";
     assert parser.mark < len        : "mark is after buffer end";
     assert parser.field_len <= len  : "field has length longer than whole buffer";
     assert parser.field_start < len : "field starts after buffer end";

     if(parser.body_start>0) {
        /* final \r\n combo encountered so stop right here */
        parser.nread++;
     }

     return parser.nread;
   }

   public int finish() {
     int cs = parser.cs;

     parser.cs = cs;
 
    if(has_error()) {
      return -1;
    } else if(is_finished()) {
      return 1;
    } else {
      return 0;
    }
  }

  public boolean has_error() {
    return parser.cs == http_parser_error;
  }

  public boolean is_finished() {
    return parser.cs == http_parser_first_final;
  }
}
