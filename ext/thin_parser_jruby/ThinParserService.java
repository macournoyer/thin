import java.io.IOException;
        
import org.jruby.Ruby;
import org.jruby.runtime.load.BasicLibraryService;

import org.thin.HttpParser;

public class ThinParserService implements BasicLibraryService { 
    public boolean basicLoad(final Ruby runtime) throws IOException {
        HttpParser.createHttp(runtime);
        return true;
    }
}
