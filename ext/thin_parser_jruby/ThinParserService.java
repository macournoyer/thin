import java.io.IOException;
        
import org.jruby.Ruby;
import org.jruby.runtime.load.BasicLibraryService;

import org.thin.Http;

public class ThinParserService implements BasicLibraryService { 
    public boolean basicLoad(final Ruby runtime) throws IOException {
        Http.createHttp(runtime);
        return true;
    }
}
