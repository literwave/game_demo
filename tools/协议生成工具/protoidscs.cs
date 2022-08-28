
using Google.Protobuf;
using System.Collections.Generic;
namespace protos
{
	class protoids
	{
		public delegate object Fn(byte[] data);
		public static Dictionary<int, string> idnames = new Dictionary<int, string>(){
		};
		public static Dictionary<string,int> nameids = new Dictionary<string, int>(){
		};
		public static Dictionary<int, Fn> ids = new Dictionary<int, Fn>(){
		};
	}
}